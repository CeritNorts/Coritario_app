import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:coritario_app/models/song.dart';
import 'package:coritario_app/screens/tabs/home_tab.dart';
import 'package:coritario_app/screens/tabs/artists_tab.dart';
import 'package:coritario_app/screens/tabs/programs_tab.dart';
import 'package:coritario_app/screens/shared_program_screen.dart';
import 'package:coritario_app/services/database_service.dart';
import 'package:coritario_app/services/update_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  List<Song> _allSongs = [];
  bool _isLoading = true;
  
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _initDeepLinking();
    _checkUpdates();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinking() async {
    _appLinks = AppLinks();

    // 1. Manejar enlaces entrantes mientras la app está abierta o en segundo plano
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Error de Deep Link: $err");
    });

    // 2. Manejar enlace inicial si la app se abrió desde frío (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Error al procesar Deep Link inicial: $e");
    }
  }

  void _handleDeepLink(Uri uri) {
    // Detectar corario://culto/detalle?songs=1,2,3... o https://ceritnorts.github.io/corario/detalle?songs=1,2,3...
    final isCustomScheme = uri.scheme == 'corario' && uri.host == 'culto' && uri.path == '/detalle';
    final isAppLink = (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'ceritnorts.github.io' &&
        uri.path == '/corario/detalle';

    if (isCustomScheme || isAppLink) {
      final songsParam = uri.queryParameters['songs'];
      if (songsParam != null && songsParam.isNotEmpty) {
        final List<String> ids = songsParam.split(',');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SharedProgramScreen(songIds: ids),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadSongs() async {
    try {
      final List<Song> loadedSongs = await DatabaseService().getSongs();
      
      setState(() {
        _allSongs = loadedSongs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading songs: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkUpdates() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final updateService = UpdateService();
      final updateInfo = await updateService.checkForUpdates();
      if (updateInfo != null && updateInfo.hasUpdate && mounted) {
        _showUpdateDialog(updateInfo);
      }
    });
  }

  void _showUpdateDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDownloading = false;
        double downloadProgress = 0.0;
        String errorMessage = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isDownloading ? Icons.downloading : Icons.system_update_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(isDownloading ? 'Descargando...' : '¡Nueva Actualización!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDownloading && errorMessage.isEmpty) ...[
                    Text(
                      'Versión disponible: ${updateInfo.version} (${updateInfo.buildNumber})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Novedades:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        updateInfo.changelog,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ] else if (isDownloading) ...[
                    const Text(
                      'Descargando la última versión del APK. Por favor espera...',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: downloadProgress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Error al descargar: $errorMessage',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: isDownloading
                  ? []
                  : [
                      if (errorMessage.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              errorMessage = '';
                              isDownloading = false;
                              downloadProgress = 0.0;
                            });
                          },
                          child: const Text('Reintentar'),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(errorMessage.isNotEmpty ? 'Cerrar' : 'Más tarde'),
                      ),
                      if (errorMessage.isEmpty)
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              isDownloading = true;
                              errorMessage = '';
                              downloadProgress = 0.0;
                            });

                            final updateService = UpdateService();
                            updateService.downloadAndInstallApk(
                              url: 'https://ceritnorts.github.io/corario/app-release.apk',
                              onProgress: (progress) {
                                setState(() {
                                  downloadProgress = progress;
                                });
                              },
                              onComplete: () {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              onError: (error) {
                                setState(() {
                                  isDownloading = false;
                                  errorMessage = error;
                                });
                              },
                            );
                          },
                          child: const Text('Actualizar'),
                        ),
                    ],
            );
          },
        );
      },
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definimos las vistas de las 3 pestañas
    final List<Widget> tabs = [
      HomeTab(
        allSongs: _allSongs,
        onNavigateToArtists: () => _onTabTapped(1), // Accesibilidad rápida
        onNavigateToPrograms: () => _onTabTapped(2),
      ),
      ArtistsTab(allSongs: _allSongs),
      const ProgramsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Coritario'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : tabs[_currentIndex],
      // Material 3 NavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Artistas',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: 'Programas',
          ),
        ],
      ),
    );
  }
}
