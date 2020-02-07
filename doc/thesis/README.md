# Thesis Latex Projects

  
La generación de la memoria del TFG se basa en dos proyectos de LaTeX distintos, **david_carrascal-TFG** y **portada-uah_eps-TFG**

El motivo de que haya dos proyectos distintos para generar una única memoria es debido a que se quiso hacer uso de dos plantillas distintas para quedarse con lo mejor de cada una. Una de ellas es la plantilla desarrollada por J.Macias para los estudiantes de la UAH (Universidad de Alcalá), y la otra, es la plantilla generada por Jose Manuel Requena Plens (Universidad de Alicante). A continuación, los enlaces a dichas plantillas:

- [Plantilla UAH creada por J.Macias](www.depeca.uah.es/images/plantillas/book-latex.zip).
- [Plantilla UA creada por J.M Requena](github.com/jmrplens/TFG-TFM_EPS).

De la plantilla de la UAH se ha utilizado las partes estandarizadas por la universidad que toda memoria de TFG debe tener (Portada, contraportada, hoja de calificación del tribunal). Y en cuanto a la plantilla de la Universidad de Alicante se ha hecho uso de todos sus estilos, fuentes, paquetes y estructura organizativa, todo ello recogido en su plantilla.

Ha supuesto un reto la integración de ambas plantillas ya que una estaba diseñada para ser compilada con pdfLatex y la otra estaba diseñada para ser compilada con XeLaTeX, por ello, el flujo de trabajo establecido para trabajar con ambas es el siguiente:

1. Generar pdf con portadas del TFG del proyecto  **portada-uah_eps-TFG**.
2. Añadir el pdf con las portadas en el proyecto principal, **david_carrascal-TFG**
3. Compilar el proyecto principal, **david_carrascal-TFG**, con XeLaTeX para generar la memoria final. El pdf con las portadas se incluye directamente al pdf resultante de la memoria del TFG para así evitar problemas de integración entre ambos proyectos.

Si dado el caso se necesitara generar nuevas portadas, se debería modificar el proyecto por el cual se generan las portadas, obtener el pdf con las portadas actualizadas e incluirlo en el proyecto principal de la memoria del TFG(**david_carrascal-TFG**). 




