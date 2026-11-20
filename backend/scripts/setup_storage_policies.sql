-- ============================================================
-- Supabase Storage Policies Setup
-- Bucket: img-proyecto-3
-- ============================================================

-- 1. Verificar que el bucket existe (debe crearse desde el Dashboard)
-- Si no existe, créalo desde: Supabase Dashboard → Storage → Create Bucket
-- Nombre: img-proyecto-3, Público: Sí

-- 2. Eliminar políticas existentes (si las hay)
DROP POLICY IF EXISTS "Public read access for vehicle images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload vehicle images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update vehicle images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete vehicle images" ON storage.objects;

-- 3. Crear política de lectura pública
-- Permite que cualquiera (incluso sin autenticación) pueda leer las imágenes
CREATE POLICY "Public read access for vehicle images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'img-proyecto-3');

-- 4. Crear política de subida para usuarios autenticados
-- Solo usuarios con token JWT válido pueden subir imágenes
CREATE POLICY "Authenticated users can upload vehicle images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'img-proyecto-3');

-- 5. Crear política de actualización para usuarios autenticados
-- Solo usuarios con token JWT válido pueden actualizar imágenes
CREATE POLICY "Authenticated users can update vehicle images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'img-proyecto-3');

-- 6. Crear política de eliminación para usuarios autenticados
-- Solo usuarios con token JWT válido pueden eliminar imágenes
CREATE POLICY "Authenticated users can delete vehicle images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'img-proyecto-3');

-- 7. Verificar que las políticas se crearon correctamente
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%vehicle images%'
ORDER BY policyname;

-- 8. Verificar que el bucket existe
SELECT 
    id,
    name,
    public,
    created_at
FROM storage.buckets 
WHERE name = 'img-proyecto-3';
