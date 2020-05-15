# Installation method

La necesidad de crear otro método de instalación es la deficiencia del los métodos alternativos de instalación que tienen aparte de Vagrant. Ellos disponen de dos shell-scripts, donde crean un enviroment muy cercano a personas con poco conocimiento de Linux, facilitándoles user propio p4, generar iconos en el escritorio, configurar IDEs... Tareas propias de cada de desarrollador en función de sus preferencias.

Por lo que se ha decidido limpiar el proceso de instalación, dejando únicamente lo estrictamente necesario
para levantar el entorno de desarrollo de p4. Dejando únicamente un shell-script, más optimizado y más limpio. Como dato curioso, y para cualquiera que inspeccione el script dado, se verá que se ha tenido que hacer una doble llamada al shell-script ``autogen.sh``, esto se debe a la problematica encontrada correlada con este este [``issue``](https://github.com/protocolbuffers/protobuf/issues/149).

Como forma de agradecer a la organización de P4 el hecho de que tengan un buen repositorio de tutoriales
dando un buen entrypoint para los n0obies que acaban de empezar con P4 (Me incluyo) se ha ofrecido el script desarrollado de instalación para que se incorpore a la rama master de su repositorio.

Al hacer el pull-request, el mantenedor de los tutoriales le pareció una buena idea, pero el hecho de tener un método de instalación nuevo significa más trabajo para mantener el repositorio. Me pidió que tratara
de incluir la instalación nativa de Vagrant para que así con un único script podamos tener la instalación
sobre Vagrant y el método que habíamos propuesto. De momento no está incluido en el master, se puede consultar el estado del pull-request en este [enlace](https://github.com/p4lang/tutorials/pull/261).
