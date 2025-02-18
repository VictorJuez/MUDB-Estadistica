############################################################
# Variables en el conjunto de datos:
#
# year - year
# hour - hour of the day (0-23)
# season -  1 = spring, 2 = summer, 3 = fall, 4 = winter 
# holiday - whether the day is considered a holiday
# workingday - whether the day is neither a weekend nor holiday
# weather - 1: Clear, Few clouds, Partly cloudy, Partly cloudy
#           2: Mist + Cloudy, Mist + Broken clouds, Mist + Few clouds, Mist
#           3: Light Snow, Light Rain + Thunderstorm + Scattered clouds, Light Rain + Scattered clouds
#           4: Heavy Rain + Ice Pallets + Thunderstorm + Mist, Snow + Fog 
# temp - temperature in Celsius
# atemp - "feels like" temperature in Celsius
# humidity - relative humidity
# windspeed - wind speed
# variable respuesta: count - number of total rentals
#
############################################################

#-----------------------------------------------------------
#
# Parte 1. Construir modelo
#
#-----------------------------------------------------------
##-- 1.Borra todos los objetos que tengas en memoria para que no te confundan en esta pr�ctica 
## Pista: instrucci�n rm o la escoba de la ventana superior derecha

rm(list = ls())

############################################################
# Lectura de datos y inspeccion
############################################################
##-- 2.Lee los datos p1a_train.csv
## Pista: fija el directorio donde tienes los datos y leelos con la instruccion read.table
datos = read.table('../p1a_train.csv', header = TRUE, sep = ';', dec = '.', stringsAsFactors = TRUE)

##-- 3. Visualiza los datos para asegurarte que los has leido correctamente. Haz una descriptiva y elimina la variable id de tus datos por comodidad (no la utilizaras)
##-- Pista: para describir tus datos, usa la instrucci�n summary. Para eliminar la variable asigna el valor NULL a toda la variable
summary(datos)
datos$id = NULL

############################################################
# Convertir variables no numericas a factores
############################################################
##-- 4. Ya te habr�s percatado que algunas variables estan codificadas con numeros pero en realidad son variables categ�ricas.
# Para que R las trate como tales debes transformalas a la clase factor. NO transformes la variable "hour" en ning�n caso
# Pista: la instruccion factor transforma las variables numericas en factores. P.ej, si quieres transformar a factor la variable
# season, tendr�s que hacer:
# datos$season <- factor(datos$season) 

datos$year = factor(datos$year)
datos$season = factor(datos$season)
datos$holiday = factor(datos$holiday)
datos$workingday = factor(datos$workingday)
datos$weather = factor(datos$weather)


##-- 5. Inspecciona el comportamiento de la respuesta (count) en funci�n de la hora (hour) con alg�n gr�fico descriptivo.
# Seg�n lo que veas, discretiza la variable en distintas categorias y conviertela en un factor
# Pista: algun grafico hecho con boxplot o plot (con lowess opcional) te puede servir. Debes discretizar seg�n lo que te parezca m�s razonable. Por ejemplo,
# si crees que de 0 a 12 horas hay un comportamiento y de 12 a 23, otro, deber�s coger dos intervalos. Para categorizar la variable
# usa la instrucci�n cut o ifelse (si usas esta �ltima, transforma a factor posteriormente). La variable puede tener tantas categorias como
# desees pero recuerda el principio de parsimonia. Un consejo es que te guardes la nueva variable con otro nombre. As�, si te equivocas,
# conservar�s la variable original (Opcional: cuando lo tengas claro, puedes borrar la variable original si lo deseas)

plot(count~hour, datos)
datos$hourCategory = cut(datos$hour, c(0,6,8,16,19,23), labels = c('morning', 'moving', 'worktime', 'moving', 'night'), include.lowest = TRUE)
datos$hour = NULL
plot(count~hourCategory, datos)

############################################################
# Descriptiva
############################################################
##-- 6.Realiza la descriptiva para todos los pares de variables que tengas como num�ricas
# Pista: Usa la instrucci�n pairs (puede tardar unos segundos) usando solo las variables que sean numericas. Recuerda que si quieres seleccionar, por ejemplo, las variables
# 2,4 y 6 de los datos, lo puedes hacer con datos[,c(2,4,6)]
pairs(datos[, c(6:10)])

############################################################
# Eliminamos variables muy correlacionadas
############################################################
##-- 7. Hay 2 variables muy correlacionadas. No queremos variables muy correlacionadas en nuestro modelo.
# Elimina aquella de las dos que peor prediga la respuesta.
# Pista: Construye 2 modelos lineales (instruccion lm) con la variable respuesta en funci�n de cada una de estas variables. Quedate con aquella
# que tenga un R2 mayor y la otra eliminala

lmTemp = lm(count ~ temp, datos)
summary(lmTemp)
# R-squared = 0.1578 -> nos quedamos con esta

lmAtemp = lm(count ~ atemp, datos)
summary(lmAtemp)
# R-squared = 0.1537

# Elminamos atemp
datos$atemp = NULL

############################################################
# Descriptiva bivariante con la respuesta
############################################################
##-- 8a. Haz el diagrama bivariante de la respuesta (count) en funci�n de las variables 
##-- numericas que te quedan y dibuja un suavizado por encima. �Son relaciones lineales?
# Pista: usa plot para cada gr�fico y las funciones lines y lowess para el suavizado

par(mfrow=c(2,4))
for(i in 6:8){
  plot(datos$count~datos[,i],main=names(datos)[i],xlab=names(datos)[i],ylab="count")
  with(datos,lines(lowess(count~datos[,i]),col=2))
}

# Si que son relaciones lineales aunque vemos que windspeed es mas constante

##-- 8b. Haz los boxplots bivariantes con la respuesta (count) y las variables categ�ricas (factores)
# �Crees que influyen en la respuesta s�lo viendo la descriptiva?
# Pista: usa la funci�n boxplot

par(mfrow=c(2,4))
for(i in c(1, 2, 3, 4, 5, 10)){
  boxplot(datos$count~datos[,i],main=names(datos)[i],xlab=names(datos)[i],ylab="count")
}

# Algunas mas que otras, las que tienen boxplots muy similares en las diferentes categorias menos representativas van a ser (Holiday y working day)

############################################################
# Seleccion de modelo y variables
############################################################
##--9. Ajusta el modelo lineal con todas las variables que tengas e interpreta la salida de resultados (coeficientes, p-valores, R2, error residual...)
# Pista: Ajusta el modelo con la funci�n lm y guardalo en un objeto. Luego, haz el summary de dicho objeto.

mod.lm1 = lm(count~.,datos)
summary(mod.lm1)
## R-squared 0.6276
## Standard error 111.3
## Vemos que workingday y windspeed tienen una significancia muy baja


##--10. Realiza una selecci�n autom�tica de variables y discute que ha pasado
# Pista: Usa la instrucci�n step para la selecci�n

mod.lm2 = step(mod.lm1)
# Step utiliza el metodo matematico AIC para determinar que caracteristicas conviene eliminar del modelo, cuanto menor es el AIC mejor. Vemos que eliminar workingday resulta en el menor AIC.
# No se elimina ninguna mas, ya que vemos que el siguiente paso que mejor AIC resulta es eliminar <none>, es decir, ninguna variable.
# Workingday ha sido eliminada del modelo
datos$workingday = NULL

summary(mod.lm2)
## R-squared 0.6275
## standard error 111.3

############################################################
# Colinealidad
############################################################
##-- 11. Mira la colinealidad con la instrucci�n vif del paquete car.
##-- �Hay que eliminar alguna variable?�Cual eliminarias si tuvieses que eliminar una?
# Pista: Primero debes instalar y cargar el paquete car. Usa la funci�n vif para evaluar la colinealidad
library(car)
vif(mod.lm2)
# Vemos que todos los valores son menores a 5 asi que no hay que eliminar ninguna variable
# Elminariamos las que tienen un mayor valor de vif, en este caso seria la variable season con un vif de 3.169

############################################################
# Validacion
############################################################
##-- 12. Haz la validaci�n con el an�lisis de residuos
##-- �Se cumplen las premisas de linealidad, normalidad, homoscedasticidad, independencia?
# Pista: Haciendo plot del modelo podr�s evaluar las tres primeras premisas. Para la independencia, dibuja los residuos en el orden
# que te aparecen en los datos (funciones plot y resid)
par(mfrow=c(2,2))
plot(mod.lm2)
plot(resid(mod.lm2))

# Forma de cono clara -> Homocedasticidad, no se cumple, hay que arreglarlo
# linealidad -> observamos curvatura, no se cumple, hay que arreglarlo
# Normalidad -> Se cumple pero es mejorable
# independencia -> Se cumple, vemos la misma varianza de los residuos a lo largo del orden en que aparecen, sin ningun patron que indique dependencia de las muestras

############################################################
# Transformacion de boxCox
############################################################
##-- 13. Si crees que no se cumple alguna premisa, haz la transformaci�n de boxCox para la variable respuesta 
##-- Escoge el valor de lambda que maximiza la funci�n y aplicala a la respuesta (count). Prueba tambien la transformacion logaritmica
# Pista: usa la funci�n de boxCox para conocer la lambda. Guardate las nuevas respuestas en unas nuevas variables llamadas countBC y countLog

par(mfrow=c(1,1))
bc <- boxCox(mod.lm2)
lamb = bc$x[which.max(bc$y)]
datos$countBC <- datos$count^lamb
datos$countLog <- log(datos$count)


############################################################
# Nuevos modelos con respuestas transformadas
############################################################
##-- 14. Ajusta los modelos con las dos nuevas respuestas. �Cu�l predice mejor seg�n el R2?
# Pista: Ajusta los modelos con la instruccion lm

mod.lm3 = lm(countBC ~ year + season + holiday + weather + temp + humidity + windspeed + hourCategory, datos)
mod.lm3 = step(mod.lm3) ## Validar que no se elimina ninguna variable mas
summary(mod.lm3)
## R-squared: 0.7418
## standard error: 0.5919
## Vemos que el R-squared augmenta en gran medida respecto el modelo anterior (lm2) 0.7418 vs 0.6275. 
## Por otra parte el error residual se disminuye drasticamente, 111.3 vs 0.5919 ahora, pero hay que considerar que este modelo utiliza la transformacion de BoxCox con lo cual los valores son mucho mas pequenos que los originales y por eso el error es menor

mod.lm4 = lm(countLog ~ year + season + holiday + weather + temp + humidity + windspeed + hourCategory,datos)
mod.lm4 = step(mod.lm4) ## Validar que no se elimina ninguna variable mas
summary(mod.lm4)
## R-squared: 0.7184 
## standard error: 0.7899
## Vemos que es ligeramente peor queBoxCox, tenemos un R-squared 0.7184 vs 0.7418 en el que utilizamos BoxCox. Asi que descartamos este y nos quedamos con lm3
## mod.lm3 con transformacion BoxCox da mejor resultado

############################################################
# Validacion
############################################################
##-- 15. Haz la validacion para los 2 modelos anteriores
# Pista: Haciendo plot del modelo podr�s evaluar las tres primeras premisas. Para la independencia, dibuja los residuos en el orden
# que te aparecen en los datos (funciones plot y resid)

par(mfrow=c(2,2))
plot(mod.lm3)
plot(resid(mod.lm3))
## Linealidad = se cumple, hay curvatura pero muy leve
## Homoscedasticidad = sigue habiendo mas dispersion en el centro que en los extremos, pero ya no tenemos forma de cono que teniamos en el modelo lm2 por lo que ha mejorado
## Normalidad = ha mejorado aunque mantiene aun cierto grado de variacion en los extremos

par(mfrow=c(2,2))
plot(mod.lm4)
plot(resid(mod.lm4))
## Peores resultados que el modelo 3
## Homocedasticidad = no se cumple hay forma de cono inverso
## Normalidad = no se cumple, y aun peor que en el modelo lm3
## linealidad = si se puede considerar que la cumple ya que presenta poca curvatura

############################################################
# Transformaciones polinomicas
############################################################
##-- 16. Escoge la respuesta que creas mejor para tus datos (count,countBC,countLog). Mira si alguna de las variables numericas 
# se podria ajustar por un relaci�n no lineal de forma descriptiva
# Pista: si has cambiado de variable respuesta, vuelve a hacer los gr�ficos bivariantes y los suavizados

par(mfrow=c(2,4))
for(i in 5:7){
  plot(datos$countBC~datos[,i],main=names(datos)[i],xlab=names(datos)[i],ylab="countBC")
  with(datos,lines(lowess(countBC~datos[,i]),col=2))
}

## Vemos que las categorias (temp, humidity y windspeed) siguen una relacion lineal respecto la variable countBC, con poca curvatura.

##-- 17. Para aquella o aquellas variables que lo creas necesario, ajusta un polinomio con todas las variables que tengas y
##-- vuelve a hacer la validacion

mod.lm5 = lm(countBC ~ year + season + holiday + weather + poly(temp,2) + poly(humidity,2) + poly(windspeed,2) + hourCategory,datos)
mod.lm5 = step(mod.lm5)
summary(mod.lm5)
## R-squared = 0.7449
## residual standard error = 0.5884
## Vemos que hay una diferencia insignificante respecto al modelo lm3, hablamos de milesimas, por lo que no vemos que sea necesario utilizar las transformaciones polinomicas

par(mfrow=c(2,2))
plot(mod.lm5)
plot(resid(mod.lm5))

# Comparacion de modelos
summary(mod.lm1)
summary(mod.lm2)
summary(mod.lm3)
summary(mod.lm4)
summary(mod.lm5)

############################################################
# Observaciones influyentes
############################################################
##-- 18. Mira la distancia de cook para todas las observaciones. Aquellas que tengan la distancia de cook mayor, son m�s influyentes
##-- Si lo crees conveniente, elimina aquellas que creas que condicionan mucho el modelo y ajusta el modelo sin estas observaciones
# Pista: Usa la instruccion cooks.distance para obtener las distancias de cook. Para eliminar observaciones, create un nuevo conjunto de datos que no tenga dichas
# observaciones. Si, por ejemplo, quieres eliminar las observaciones 1, 2 y 5, entonces datos2 <- datos[-c(1,2,5),]
# Modelo definitivo

influenceIndexPlot(mod.lm3)
cooksDistance = cooks.distance(mod.lm3)
## A eliminar: 2005, 6737
influencePlot(mod.lm3)

datos2 = datos[-c(2005,6737),]
mod.lm6 = lm(countBC ~ year + season + holiday + weather + temp + humidity + windspeed + hourCategory,datos2)
summary(mod.lm6)
## R-squared: 0.7425
## Residual standard error: 0.5911
## Hay una mejora casi insignificante respecto el modelo lm3, asi que nos quedamos con el anterior

par(mfrow=c(2,2))
plot(mod.lm6)


### MODELO FINAL
mod.final = mod.lm3
library('effects')
plot(allEffects(mod.final))

## Ver predicciones vs valores reales
pr = predict(mod.final, datos)
par(mfrow=c(1,1))
plot(pr,datos$countBC)
abline(0,1,col=2,lwd=2)    

##-- 19. Opcional: haz todo lo que tu creas necesario para mejorar el modelo (si es que hay algo que lo pueda mejorar)

############################################################
#
# Parte 2. Hacer prediciones con la muestra test
#
############################################################
##-- 20. Lee los datos test (p1a_test.csv) con la instruccion read.table
datosTest = read.table('../p1a_test.csv', header = TRUE, sep = ';', dec = '.', stringsAsFactors = TRUE)

############################################################
# Transformaciones en variables
############################################################
##-- 21. Haz EXACTAMENTE las mismas transformaciones que hicieste en el conjunto de entrenamiento (tranformar a factores
# algunas variables, eliminar variables, categorizar o cualquier otro cambio que hayas hecho). NO ELIMINES LA VARIABLE id (Identificador)

## Convertir a factores
datosTest$year = factor(datosTest$year)
datosTest$season = factor(datosTest$season)
datosTest$holiday = factor(datosTest$holiday)
datosTest$workingday = factor(datosTest$workingday)
datosTest$weather = factor(datosTest$weather)

## Categorizar hora
datosTest$hourCategory = cut(datosTest$hour, c(0,6,8,16,19,23), labels = c('morning', 'moving', 'worktime', 'moving', 'night'), include.lowest= TRUE)
datosTest$hour = NULL

## Eliminar variables
datosTest$atemp = NULL
datosTest$workingday = NULL

############################################################
# Calcular predicciones
############################################################
##-- 22. Usa la instrucci�n predict aplicada al modelo que tu has escogido para
##-- obtener las predicciones en la muestra test.
# Pista: la instruccion predict debe tener 2 parametros: el modelo final y los datos test con las variables transformadas. Guardate las
# prediciones en una variable del mismo conjunto de datos

prediccionesBC = predict(mod.final, datosTest)
datosTest$predicciones = prediccionesBC^(1/lamb)

############################################################
# Guardar fichero
############################################################
##-- 23. Escribe un fichero con solo dos columnas el identificador y la predici�n
# Pista: Usa la funcion write.table y sigue escrupulosamente las instrucciones del enunciado para generar este fichero
# (quote = FALSE, sep = ";", row.names = FALSE, col.names = FALSE)

write.table(datosTest[c('id','predicciones')], file='p1a.txt', quote = FALSE, sep = ";", row.names = FALSE, col.names = FALSE)
