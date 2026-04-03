#!/bin/bash

# Instalar Android SDK en /home donde hay espacio

echo "📱 Instalando Android SDK Command Line Tools..."

# Crear directorio en /home
ANDROID_HOME="$HOME/Android/Sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"

cd "$ANDROID_HOME/cmdline-tools"

# Descargar command line tools
echo "Descargando Android Command Line Tools..."
wget -q --show-progress https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

# Extraer
echo "Extrayendo..."
unzip -q commandlinetools-linux-11076708_latest.zip
mv cmdline-tools latest
rm commandlinetools-linux-11076708_latest.zip

# Configurar variables de entorno
echo ""
echo "📝 Configurando variables de entorno..."

if ! grep -q "ANDROID_HOME" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Android SDK" >> ~/.bashrc
    echo "export ANDROID_HOME=$HOME/Android/Sdk" >> ~/.bashrc
    echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"' >> ~/.bashrc
    echo 'export PATH="$ANDROID_HOME/platform-tools:$PATH"' >> ~/.bashrc
fi

# Aplicar cambios
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

# Instalar componentes necesarios
echo ""
echo "📦 Instalando componentes de Android..."
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis;x86_64"

# Configurar Flutter
export PATH="$HOME/flutter/bin:$PATH"
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
flutter config --android-sdk "$ANDROID_HOME"

echo ""
echo "✅ Android SDK instalado en $ANDROID_HOME"
echo ""
echo "🔍 Verificando instalación..."
flutter doctor

echo ""
echo "📱 Para crear un emulador:"
echo "   avdmanager create avd -n test_device -k 'system-images;android-34;google_apis;x86_64'"
echo ""
echo "🚀 Para iniciar el emulador:"
echo "   emulator -avd test_device"
