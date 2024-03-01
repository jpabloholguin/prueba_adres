# Script "R" para prueba de selección analista de datos ADRES

# Inicialmente se crea la base de datos en SQLite y sus dos tablas "Municipios" y "Prestadores"

# Limpiar ambiente de trabajo
rm(list=ls(all=TRUE))

# Cargar ibrerías necesarias para análisis de datos
library(RSQLite)
library(readxl)

# Ruta a los archivos Excel
ruta_archivo_municipios <- 'C:/Prueba_adres/datos/Municipios.xlsx'
ruta_archivo_prestadores <- 'C:/Prueba_adres/datos/Prestadores2.xlsx'

# Leer archivos Excel
datos_municipios <- read_excel(ruta_archivo_municipios)
datos_prestadores <- read_excel(ruta_archivo_prestadores)

# Establecer la conexión a la base de datos SQLite
con <- dbConnect(SQLite(), dbname = 'C:/Prueba_adres/bd_prueba_adres.db')

# Insertar datos en las tablas de SQLite
dbWriteTable(con, "Municipios", datos_municipios, overwrite = TRUE)
dbWriteTable(con, "Prestadores", datos_prestadores, overwrite = TRUE)

## Ejecución de consultas SQL en la bd conectada para exploración de datos ##
# Consulta 1: Ver las primeras filas de la tabla Municipios
consulta_1 <- "SELECT * FROM Municipios LIMIT 5;"
resultado_1 <- dbGetQuery(con, consulta_1)
print(resultado_1)

# Consulta 2: Ver las primeras filas de la tabla Prestadores
consulta_2 <- "SELECT * FROM Prestadores LIMIT 5;"
resultado_2 <- dbGetQuery(con, consulta_2)
print(resultado_2)

# Consulta 3: Número de filas en la tabla "Municipios"
consulta_3 <- "SELECT COUNT (*) FROM Municipios;"
resultado_3 <- dbGetQuery(con, consulta_3)
print(resultado_3)

# Consulta 4: Número de filas en la tabla "Prestadores"
consulta_4 <- "SELECT COUNT (*) FROM Prestadores;"
resultado_4 <- dbGetQuery(con, consulta_4)
print(resultado_4)

# Consulta 5: Encontrar filas duplicadas en la tabla "Municipios"
consulta_5 <- "
    SELECT Departamento, Dep, Municipio, Depmun, Superficie, Poblacion, Irural, Region, COUNT(*) AS Num_Duplicados
    FROM Municipios
    GROUP BY Departamento, Dep, Municipio, Depmun, Superficie, Poblacion, Irural, Region
    HAVING COUNT(*) > 1;"
resultado_5 <- dbGetQuery(con, consulta_5)
print(resultado_5)

# Consulta 6: Encontrar filas duplicadas en la tabla "Prestadores"
consulta_6 <- "
    SELECT depa_nombre, muni_nombre, codigo_habilitacion, nombre_prestador, tido_codigo, nits_nit, razon_social, clpr_codigo, clpr_nombre, ese, direccion, telefono, fax, email, gerente, nivel, caracter, habilitado, fecha_radicacion, fecha_vencimiento, fecha_cierre, dv, clase_persona, naju_codigo, naju_nombre, numero_sede_principal, fecha_corte_REPS, telefono_adicional, email_adicional, rep_legal, COUNT(*) AS Num_Duplicados
    FROM Prestadores
    GROUP BY depa_nombre, muni_nombre, codigo_habilitacion, nombre_prestador, tido_codigo, nits_nit, razon_social, clpr_codigo, clpr_nombre, ese, direccion, telefono, fax, email, gerente, nivel, caracter, habilitado, fecha_radicacion, fecha_vencimiento, fecha_cierre, dv, clase_persona, naju_codigo, naju_nombre, numero_sede_principal, fecha_corte_REPS, telefono_adicional, email_adicional, rep_legal
    HAVING COUNT(*) > 1;"
resultado_6 <- dbGetQuery(con, consulta_6)
print(resultado_6)

# Consulta 7: Conocer el número de prestadores por municipio
consulta_7 <- "
  SELECT muni_nombre, COUNT(*) AS numero_prestadores
  FROM Prestadores
  GROUP BY muni_nombre
  ORDER BY numero_prestadores DESC;
"
resultado_7 <- dbGetQuery(con, consulta_7)
print(resultado_7)

# Consulta 8: Conocer el número de prestadores por naturaleza jurídica por municipio
consulta_8 <- "
  SELECT muni_nombre, naju_nombre, COUNT(*) AS numero_prestadores
  FROM Prestadores
  GROUP BY muni_nombre, naju_nombre
  ORDER BY numero_prestadores DESC;
"
resultado_8 <- dbGetQuery(con, consulta_8)
print(resultado_8)

# Consulta 9: Crear la columna "densidad_poblacional" en la tabla "Municipios" y seleccionar los 5 municipios con mayor densidad poblacional
consulta_3 <- "
  -- Agregar una nueva columna llamada 'densidad_poblacional'
  ALTER TABLE Municipios
  ADD COLUMN densidad_poblacional NUMERIC;

  -- Actualizar la nueva columna con el cálculo de la densidad poblacional
  UPDATE Municipios
  SET densidad_poblacional = Poblacion / Superficie;
"
resultado_9 <- dbExecute(con, consulta_9)
resultado_9 <- dbGetQuery(con, "SELECT * FROM Municipios ORDER BY densidad_poblacional DESC
  LIMIT 5;")
print(resultado_9)


## Explorar distribución y normalidad de variables numéricas ##
# Ajustar el tamaño de la ventana gráfica y crear el histograma
windows(width = 10, height = 6)
hist(datos_municipios$Superficie, main = "Histograma de Superficie", xlab = "Superficie")

# Ajustar el tamaño de la ventana gráfica y crear el gráfico de densidad
windows(width = 10, height = 6)
plot(density(datos_municipios$Poblacion), main = "Densidad de Población", xlab = "Población")

# Prueba de Shapiro-Wilk para la variable superficie
shapiro.test(datos_municipios$Superficie)

# Ajustar el tamaño de la ventana gráfica y crear el gráfico Q-Q
windows(width = 10, height = 6)
qqnorm(datos_municipios$Poblacion)
qqline(datos_municipios$Poblacion)

# Ajustar el tamaño de la ventana gráfica y crear el histograma
windows(width = 10, height = 6)
hist(datos_municipios$Irural, main = "Histograma de Irural", xlab = "Irural")


## Unir conjuntos de datos Municipios y Prestadores ##
# Agregar una nueva columna llamada "Depmun" a la tabla "Prestadores"
consulta_10_1 <- "ALTER TABLE Prestadores ADD COLUMN Depmun TEXT;"

# Actualizar la nueva columna con los primeros 5 caracteres de la variable "codigo_habilitacion"
consulta_10_2 <- "UPDATE Prestadores SET Depmun = SUBSTR(codigo_habilitacion, 1, 5);"

# Ejecutar las consultas
resultado_10_1 <- dbExecute(con, consulta_10_1)
resultado_10_2 <- dbExecute(con, consulta_10_2)
print(resultado_10_2)

# Consulta 11: Realizar un left join entre las tablas datos_municipios y datos_prestadores utilizando la variable Depmun como clave de unión
consulta_11 <- "
  CREATE TABLE Prestadores_en_municipios AS 
  SELECT *
  FROM Municipios AS m
  INNER JOIN Prestadores AS p
  ON m.Depmun = p.Depmun;
"
# Ejecutar la consulta para crear la tabla
dbExecute(con, consulta_11)

# Consulta para seleccionar los datos de la tabla Prestadores_en_municipios
consulta_select <- "SELECT * FROM Prestadores_en_municipios;"

# Obtener los resultados del left join
resultado_11 <- dbGetQuery(con, consulta_select)

# Imprimir los resultados
print(resultado_11)

# Cerrar conexión
dbDisconnect(con)


## EXPORTAR A CSV PARA LLEVAR A POWER BI ##
# ruta y nombre de archivo para guardar el CSV
ruta_archivo <- "C:/Prueba_adres/datos/Prestadores_en_municipios.csv"

# ExportaR el objeto resultado_11 como un archivo CSV delimitado por punto y coma
write.csv2(resultado_11, file = ruta_archivo, row.names = FALSE)
