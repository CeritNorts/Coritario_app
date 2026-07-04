import json
import os
import sys

# Intentar importar firebase-admin, si no está instalado avisar al usuario
try:
    import firebase_admin
    from firebase_admin import credentials
    from firebase_admin import firestore
except ImportError:
    print("Error: El paquete 'firebase-admin' no está instalado.")
    print("Por favor, ejecuta: pip install firebase-admin")
    sys.exit(1)

def upload_songs():
    import_file = 'firestore_import.json'
    service_account_file = 'service-account.json'

    # Verificar que el archivo JSON de datos exista
    if not os.path.exists(import_file):
        print(f"Error: No se encontró el archivo '{import_file}' en la raíz del proyecto.")
        sys.exit(1)

    # Verificar que las credenciales de Firebase Admin existan
    if not os.path.exists(service_account_file):
        print(f"Error: No se encontró el archivo de credenciales '{service_account_file}' en la raíz.")
        print("\nPara descargarlo:")
        print("1. Ve a la Consola de Firebase -> Configuración del Proyecto (icono de engranaje).")
        print("2. Pestaña 'Cuentas de servicio'.")
        print("3. Haz clic en 'Generar nueva clave privada'.")
        print("4. Guarda el archivo descargado como 'service-account.json' en la raíz de este proyecto.")
        sys.exit(1)

    # Cargar datos del JSON
    with open(import_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    canciones = data.get('canciones', {})
    if not canciones:
        print("Error: No se encontraron cantos en el nodo 'canciones' del archivo JSON.")
        sys.exit(1)

    # Inicializar Firebase Admin SDK
    print("Inicializando Firebase Admin...")
    cred = credentials.Certificate(service_account_file)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    print(f"Preparando la subida de {len(canciones)} cantos a la colección 'canciones'...")

    # Subir en lotes (batch) para optimizar y no exceder los límites de Firestore (máx. 500 por lote)
    batch = db.batch()
    count = 0
    batch_size = 400

    for doc_id, doc_data in canciones.items():
        doc_ref = db.collection('canciones').document(doc_id)
        batch.set(doc_ref, doc_data)
        count += 1

        if count % batch_size == 0:
            batch.commit()
            batch = db.batch()
            print(f"-> {count} cantos subidos con éxito...")

    # Subir el remanente
    if count % batch_size != 0:
        batch.commit()

    print(f"\n¡Completado! Se subieron un total de {count} cantos a Firestore de forma exitosa.")

if __name__ == '__main__':
    upload_songs()
