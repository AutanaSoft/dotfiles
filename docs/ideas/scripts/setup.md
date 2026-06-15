# Setup scripts - Ideas

Los scripts para instalar las configuraciones deberían estar orientados con una lógica simple, pero
manteniendo las validaciones necesarias para evitar errores en su ejecución.

## Setup script

El setup script es el orquestador de las instalaciones, solo debe encargarse de recibir los
argumento que se van a validar y ejecutar, también debe de encargarse inicial las variables
necesarias para que los otros script funcionen correctamente. al finalizar tiene que hacer una
limpieza se las variables que se exportaron para que no queden en el sistema.

### argumento

- --fonts: instalar las fuentes.
- --deps: instala las dependencias dependiendo de la distribución donde se esta ejecutando
- --dry-run: Imprime las acciones que se van a ejecutar pero no modifica el entorno
- --omarchy: configura el entorno para omarchy o CachyOS + omarchy
- --fedora: configura el entorno para fedora, este scripts no esta disponibles y no se va a
  implementar por ahora.

### Comando disponibles

- ./setup --fonts: lanza el script para la instalación de las fuentes
- ./setup --deps: laza el script para la instalación de las dependencias
- ./setup --omarchy: lanza el script para la configuración de omarchy.
- ./setup --omarchy --dry-run: lanza el script para la configuración de omarchy.
- ./setup --fedora: debe solo imprimir un mensaje de no implementado.
- ./setup --fedora --dry-run: solo debe imprimir un mensaje de no implementado

## Script de configuraciones

Los script de configuraciones deben recibir las variables necesarias para su ejecución, la
responsabilidad de estos scripts son:

- verificar las dependencias
- instalar las fuentes
- configurar el entorno
