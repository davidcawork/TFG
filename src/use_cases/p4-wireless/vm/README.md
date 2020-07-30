# Installation method

The need to create another installation method is the deficiency of the alternative installation methods they have other than Vagrant. They have two shell-scripts, where they create an environment very close to people with little knowledge of Linux, providing them with their own user p4, generate icons on the desktop, configure IDEs... Each developer's own tasks according to their preferences.

So it has been decided to clean up the installation process, leaving only the strictly necessary
to raise the p4 development environment. Leaving only one shell-script, more optimized and cleaner. As a curiosity, and for anyone who inspects the given script, it will be seen that a double call to the shell-script ``autogen.sh`` has had to be made, this is due to the problems found correlated with this [``issue``](https://github.com/protocolbuffers/protobuf/issues/149).

As a way of thanking the P4 organization for having a good tutorial repository
giving a good entrypoint for n0obies that have just started with P4 (Me included) the developed installation script has been offered to be incorporated into the master branch of your repository.

When doing the pull-request, the tutorial maintainer seemed like a good idea, but having a new installation method means more work to maintain the repository. He asked me to try
to include the native installation of Vagrant so that with a single script we can have the
about Vagrant and the method we had proposed. At the moment it is not included in the master, you can check the status of the pull-request in this [link](https://github.com/p4lang/tutorials/pull/261).

---

# Installation method

La necesidad de crear otro método de instalación es la deficiencia del los métodos alternativos de instalación que tienen aparte de Vagrant. Ellos disponen de dos shell-scripts, donde crean un enviroment muy cercano a personas con poco conocimiento de Linux, facilitándoles user propio p4, generar iconos en el escritorio, configurar IDEs... Tareas propias de cada de desarrollador en función de sus preferencias.

Por lo que se ha decidido limpiar el proceso de instalación, dejando únicamente lo estrictamente necesario
para levantar el entorno de desarrollo de p4. Dejando únicamente un shell-script, más optimizado y más limpio. Como dato curioso, y para cualquiera que inspeccione el script dado, se verá que se ha tenido que hacer una doble llamada al shell-script ``autogen.sh``, esto se debe a la problematica encontrada correlada con este este [``issue``](https://github.com/protocolbuffers/protobuf/issues/149).

Como forma de agradecer a la organización de P4 el hecho de que tengan un buen repositorio de tutoriales
dando un buen entrypoint para los n0obies que acaban de empezar con P4 (Me incluyo) se ha ofrecido el script desarrollado de instalación para que se incorpore a la rama master de su repositorio.

Al hacer el pull-request, el mantenedor de los tutoriales le pareció una buena idea, pero el hecho de tener un método de instalación nuevo significa más trabajo para mantener el repositorio. Me pidió que tratara
de incluir la instalación nativa de Vagrant para que así con un único script podamos tener la instalación
sobre Vagrant y el método que habíamos propuesto. De momento no está incluido en el master, se puede consultar el estado del pull-request en este [enlace](https://github.com/p4lang/tutorials/pull/261).

