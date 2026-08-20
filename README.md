# Dynamic Lyrics para CarPlay — guía de instalación (sin Mac, sin pagar)

App personal para ver la letra sincronizada de lo que suena en Apple Music, como
widget en el dashboard de CarPlay (iOS 26). Construida para instalarse sin Mac y
sin la cuenta paga de Apple Developer, usando herramientas gratuitas de la
comunidad. Es una ruta avanzada con varias piezas — sigue los pasos en orden y
no te preocupes si algo no sale a la primera, son herramientas que se actualizan
seguido y a veces hay que ajustar un detalle.

## Qué incluye este proyecto

- `project.yml` — definición del proyecto para [XcodeGen](https://github.com/yonaskolb/XcodeGen), que genera el `.xcodeproj` automáticamente (así no dependemos de que Xcode local exista).
- `App/` — la app principal: detecta qué suena en Apple Music y busca la letra sincronizada en [LRCLIB](https://lrclib.net) (base de datos abierta y gratuita de letras, sin necesitar cuenta ni API key).
- `Widget/` — el widget que se muestra en CarPlay, con la línea actual resaltada y la anterior/siguiente atenuadas (estilo karaoke).
- `Shared/` — código compartido entre la app y el widget.
- `.github/workflows/build.yml` — workflow de GitHub Actions que compila el proyecto en un runner de macOS gratuito y te deja un `.ipa` sin firmar listo para descargar.

## Paso 1 — Subir el código a GitHub

1. Crea una cuenta gratuita en [github.com](https://github.com) si no tienes una.
2. Crea un repositorio nuevo (puede ser privado) y sube esta carpeta completa
   (todos los archivos que te envié, manteniendo la misma estructura de carpetas).
   Puedes hacerlo desde la app de GitHub para iPhone, o subiendo los archivos
   por la web en github.com desde el navegador de tu iPhone (botón "Add file" →
   "Upload files").

## Paso 2 — Compilar el .ipa sin firmar

1. En tu repositorio, ve a la pestaña **Actions**.
2. Verás el workflow **"Build unsigned IPA"**. Actívalo si te lo pide, y luego
   dale a **"Run workflow"**.
3. Espera a que termine (unos 5-10 minutos). Cuando termine en verde, entra al
   run y baja hasta **Artifacts** → descarga `DynamicLyrics-unsigned-ipa`.
4. Eso te da un archivo `DynamicLyrics-unsigned.ipa`. Ese archivo aún no sirve
   para instalar — falta firmarlo con tu Apple ID, que es el siguiente paso.

> Nota: GitHub da minutos gratis de Actions al mes en cuentas personales. Para
> este proyecto (una compilación ocasional) no deberías acercarte al límite.

## Paso 3 — Firmar el .ipa con tu Apple ID (SignTools)

[SignTools](https://github.com/SignTools/SignTools) es un proyecto de código
abierto hecho exactamente para esto: "firmar apps sin computadora", usando tu
Apple ID normal (gratis) en vez de una cuenta paga.

Cómo funciona a alto nivel:

1. Despliegas tu propia instancia de SignTools (es gratis y se puede alojar en
   servicios con capa gratuita como Fly.io o Railway, conectando directamente
   tu repositorio de GitHub desde el navegador — no necesitas instalar nada en
   una computadora). Sigue la guía oficial de instalación en su repositorio:
   https://github.com/SignTools/SignTools#readme
2. Le das a SignTools tu Apple ID (usa una **contraseña de aplicación**
   específica, no tu contraseña normal — se genera en appleid.apple.com).
   SignTools la usa solo para pedir el certificado de firma gratuito de Apple,
   igual que haría Xcode.
3. Desde la interfaz web de SignTools (accesible desde Safari en tu iPhone),
   subes el `DynamicLyrics-unsigned.ipa` del paso anterior.
4. SignTools lo firma y te da un `.ipa` ya firmado, listo para instalar.

**Importante sobre seguridad:** solo usa una instancia de SignTools que tú
mismo despliegues (no un servicio de terceros desconocido), porque le vas a
dar tu Apple ID. La contraseña de aplicación se puede revocar en cualquier
momento desde appleid.apple.com si algo sale mal.

## Paso 4 — Instalar y mantener la app con SideStore

[SideStore](https://sidestore.io) es la app que queda instalada en tu iPhone
y renueva la firma automáticamente cada 7 días por WiFi (límite que Apple
impone a las cuentas gratuitas), sin que tengas que hacer nada manual.

1. Sigue la guía oficial de instalación de SideStore (tienen instrucciones
   específicas para instalar sin computadora):
   https://docs.sidestore.io/docs/guides/install
2. Vas a necesitar generar un **"pairing file"** — un archivo que SideStore
   usa para poder renovarse solo. Se genera desde el propio iPhone con la app
   **StikDebug**: https://docs.sidestore.io/docs/advanced/pairing-file
3. Una vez SideStore esté instalado, ábrelo y usa la opción de instalar un
   `.ipa` para instalar el `DynamicLyrics-unsigned.ipa` ya firmado del Paso 3.

## Paso 5 — Activar el widget en CarPlay

1. Abre la app **Dynamic Lyrics** al menos una vez en tu iPhone y acepta el
   permiso de acceso a Apple Music cuando te lo pida.
2. Ve a **Ajustes → General → CarPlay**.
3. Selecciona tu vehículo de la lista.
4. Entra a **Widgets** (o "Personalizar") y agrega **Dynamic Lyrics**.
5. Conecta tu iPhone al carro, reproduce algo en Apple Music, y en la pantalla
   de CarPlay desliza hasta el widget.

## Limitaciones que debes conocer

- **Letras**: dependemos de LRCLIB, una base de datos abierta. Canciones muy
  nuevas o de artistas poco conocidos pueden no tener letra sincronizada
  disponible todavía.
- **Renovación cada 7 días**: es un límite de Apple para cuentas gratuitas,
  no de este proyecto. SideStore lo automatiza, pero tu iPhone necesita tener
  conexión a internet al menos una vez por semana para que se renueve sola.
- **Primera vez**: es normal que algún paso de SignTools o SideStore requiera
  un pequeño ajuste — son proyectos de comunidad que cambian con las
  actualizaciones de iOS. Si algo falla, cuéntame en qué paso y el mensaje de
  error exacto, y lo resolvemos juntos.

## Si en algún momento prefieres la ruta paga

Si esta ruta te resulta muy tediosa de mantener, recuerda que pagando los 99
USD/año de Apple Developer, todo este proceso se simplifica mucho (compilación
y firma automática en la nube vía TestFlight, sin límite de 7 días, sin
SignTools ni SideStore). Es una alternativa que sigue disponible si cambias de
opinión más adelante.
