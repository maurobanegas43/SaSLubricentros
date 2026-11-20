#!/bin/bash

# Script para verificar la configuración de Supabase Storage

echo "==================================="
echo "Verificación de Supabase Storage"
echo "==================================="
echo ""

# Cargar variables de entorno
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: No se encontró el archivo .env"
    exit 1
fi

echo "📋 Variables de entorno:"
echo ""

# Verificar cada variable
check_var() {
    local var_name=$1
    local var_value=${!var_name}
    
    if [ -z "$var_value" ]; then
        echo "❌ $var_name: NO CONFIGURADA"
        return 1
    else
        # Mostrar solo los primeros 20 caracteres para seguridad
        local preview="${var_value:0:20}..."
        echo "✅ $var_name: $preview"
        return 0
    fi
}

all_ok=true

check_var "SUPABASE_URL" || all_ok=false
check_var "SUPABASE_STORAGE_URL" || all_ok=false
check_var "SUPABASE_ANON_KEY" || all_ok=false
check_var "SUPABASE_SERVICE_ROLE_KEY" || all_ok=false
check_var "SUPABASE_STORAGE_BUCKET" || all_ok=false

echo ""
echo "==================================="

if [ "$all_ok" = true ]; then
    echo "✅ Todas las variables están configuradas"
    echo ""
    echo "🧪 Probando conexión con Supabase Storage..."
    echo ""
    
    # Test básico de conexión
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
        "$SUPABASE_STORAGE_URL/bucket/$SUPABASE_STORAGE_BUCKET")
    
    if [ "$response" = "200" ]; then
        echo "✅ Conexión exitosa con el bucket '$SUPABASE_STORAGE_BUCKET'"
    else
        echo "⚠️  Respuesta HTTP: $response"
        echo "   Verifica que:"
        echo "   1. El bucket '$SUPABASE_STORAGE_BUCKET' exista en Supabase"
        echo "   2. La SUPABASE_SERVICE_ROLE_KEY sea correcta"
    fi
else
    echo "❌ Faltan variables de configuración"
    echo ""
    echo "📝 Para obtener las claves:"
    echo "   1. Ve a https://supabase.com/dashboard"
    echo "   2. Selecciona tu proyecto"
    echo "   3. Ve a Settings > API"
    echo "   4. Copia 'service_role' key (secret)"
    echo ""
    echo "📝 Para configurar el bucket:"
    echo "   1. Ve a Storage en el dashboard"
    echo "   2. Crea el bucket 'img-proyecto-3' (público)"
fi

echo "==================================="
