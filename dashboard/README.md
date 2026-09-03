# Dashboard FV — Corval Pharmaceutical

Dashboard de farmacovigilancia para **CORVAL PHARMACEUTICAL S.A.C.**, parte de la
familia de dashboards `Dashboards-Farmaco-tecno-cosmeto` (Solton, Cobefar, PharmaCOimporters, Corval).

Sigue el mismo modelo visual usado en la web pública de Corval
(https://github.com/Russali-ux/Corval) — tipografía Raleway, rojo corporativo
`#c0392b` / coral `#F05252` — combinado con el patrón de dashboard interno ya
usado para Cobefar / PharmaCOimporters (panel de control con árbol de módulos,
autenticación Supabase y formulario de notificación).

## Qué incluye

- **Control del sistema FV**: árbol de 8 categorías / ~30 módulos, construido a
  partir de los POE reales de Corval (FV-PR002 a FV-PR006, Manual de Calidad,
  MOF, organigrama), con pills de estado clicables (Pendiente → En proceso →
  Al día → Vencido), barra de cumplimiento general, contadores, búsqueda y
  filtros, más secciones de Entrenamientos y Bases de Datos / Monitoreo.
- **Casos SRA**: listado en vivo de las notificaciones recibidas, con KPIs
  (total, graves, en seguimiento, notificados a la ANM, cerrados), gravedad,
  causalidad y un semáforo de plazo regulatorio (24 h para casos graves / 20
  días calendario para leves-moderadas, según FV-PR002). El estado de cada
  caso se puede actualizar desde el propio panel (con acceso autorizado).
- **Monitoreo de Alertas y PAVS**: clonado de [Regulator.IA-Pharma](https://github.com/Russali-ux/Regulator.IA-Pharma)
  (Monitor PAVS-LATAM) — filtros (texto, año, país, agencia, tipo, producto),
  KPIs, dos gráficos de barras (por año / top agencias) y tabla de detalle
  con exportación a CSV. A diferencia del original (que lee un JSON estático
  `data/pavs_monitor.json`), esta versión consulta **en vivo** la tabla
  compartida `public.pavs_alertas` en Supabase (alimentada a diario por el
  pipeline `PAVS_Digemid` de ese mismo repo). Requiere sesión iniciada
  (cualquier cuenta autorizada de la familia de dashboards; la política RLS
  de esa tabla es de lectura para cualquier usuario autenticado).
- **Notificar RAM / evento adverso**: formulario público de notificación
  (igual al de la web de Corval, con el listado real de productos) + panel
  informativo. Cada envío genera un código de caso tipo `COR AA NNNN`.
- **Autenticación Supabase**: Google OAuth + correo/contraseña, gateada por el
  flag `acceso_corval` en la tabla compartida `perfiles`.
- **Tiempo real**: cambios de estado de módulos y casos nuevos se reflejan en
  vivo entre sesiones (Supabase Realtime).

## Conexión a Supabase

El dashboard **ya está conectado** al proyecto compartido de la familia de
dashboards (`ggbnfdaxtsngsjssrwrl`, mismo usado por Cobefar / PAVS / CIMA /
ConkoSafe IA). Las credenciales (URL + anon key) están en las dos primeras
constantes del `<script>` al final de `index.html`.

El esquema (tablas `corval_fv_estados`, `corval_notificaciones` y la columna
`acceso_corval` en `perfiles`) ya fue creado en ese proyecto. El archivo
`supabase_setup.sql` se conserva como documentación / para reproducirlo en
otro proyecto si algún día se separa Corval a su propio proyecto Supabase.

### Dar acceso al panel a alguien del equipo

1. Que la persona se registre desde el botón **Iniciar sesión** del panel
   (correo/contraseña o Google).
2. `acceso_corval` es `true` por defecto para cualquier perfil nuevo, así que
   en la práctica no hace falta nada más. Para revocarlo:
   ```sql
   update public.perfiles set acceso_corval = false
   where email = 'persona@corval.com.pe';
   ```

## Pendientes de personalizar / mejorar

- Enlaces de módulos (OneDrive/SharePoint de Corval): cambiar los `link:"#"`
  en el arreglo `DATA` del script.
- Enlaces de Entrenamientos (actualmente apuntan a placeholders `#`).
- Si se quiere registrar los intentos de contacto/seguimiento de cada SRA
  (exigidos por FV-PR002: fecha, hora, medio, resultado), se puede agregar
  una tabla `corval_seguimientos` con FK a `corval_notificaciones`.

## Publicar (GitHub Pages)

Haz commit y push del repo; en Settings → Pages apunta a la rama/carpeta
`Corval/`.
