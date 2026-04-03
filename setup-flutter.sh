#!/bin/bash

# Script de instalación de Flutter para Linux

echo "📦 Instalando Flutter..."

# Crear directorio de instalación
cd ~

# Descargar Flutter (versión estable)
if [ ! -d "flutter" ]; then
    echo "Descargando Flutter..."
    wget -q --show-progress https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz
    
    echo "Extrayendo Flutter..."
    tar xf flutter_linux_3.27.1-stable.tar.xz
    
    echo "Limpiando archivo de descarga..."
    rm flutter_linux_3.27.1-stable.tar.xz
else
    echo "Flutter ya está descargado"
fi

# Configurar variables de entorno
echo ""
echo "📝 Configurando variables de entorno..."

# Agregar al .bashrc si no existe
if ! grep -q "flutter/bin" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Flutter" >> ~/.bashrc
    echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
    echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc
    echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.bashrc
    echo "Variables agregadas a ~/.bashrc"
else
    echo "Variables ya configuradas en ~/.bashrc"
fi

# Aplicar cambios
export PATH="$HOME/flutter/bin:$PATH"
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"

echo ""
echo "✅ Flutter instalado!"
echo ""
echo "🔍 Ejecutando flutter doctor..."
flutter doctor

echo ""
echo "⚠️  IMPORTANTE: Ejecuta 'source ~/.bashrc' o abre una nueva terminal para aplicar los cambios"
echo ""
echo "📱 Para instalar Android SDK (necesario para compilar):"
echo "   flutter doctor --android-licenses"
