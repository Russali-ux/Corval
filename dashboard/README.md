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
- **Monitoreo de Alertas y PAVS**: clonado de [Regulator.IA-Pharma](https://github.com/Russali-ux/Regulator.IA-Pharma)
  (Monitor PAVS-LATAM) — filtros (texto, año, país, agencia, tipo, producto),
  KPIs, dos gráficos de barras (por año / top agencias) y tabla de detalle
  con exportación a CSV. A diferencia del original (que lee un JSON estático
  `data/pavs_monitor.json`), esta versión consulta **en vivo** la tabla
  compartida `public.pavs_alertas` en Supabase (alimentada a diario por el
  pipeline `PAVS_Digemid` de ese mismo repo). Requiere sesión iniciada
  (cualquier cuenta autorizada de la familia de dashboards; la política RLS
  de esa tabla es de lectura para cualquier usuario autenticado).
- **Autenticación Supabase**: Google OAuth + correo/contraseña. El ingreso
  está restringido a cuentas **activas en ConkoSafe IA — Alertas DIGEMID**
  (https://russali-ux.github.io/Alertas-analyzer/): al iniciar sesión se
  comprueba el flag `acceso_pavs` (o `rol = 'admin'`) de esa persona en la
  tabla compartida `perfiles`; si no lo cumple, se cierra la sesión de
  inmediato y se muestra un aviso — no queda logueada aunque Supabase haya
  aceptado su correo/contraseña. El panel ya no tiene formulario de
  autorregistro ("Crear cuenta"), solo login, para evitar que cualquiera
  cree una cuenta nueva desde Corval y quede "autorizada" por defecto.
- **Tiempo real**: cambios de estado de módulos se reflejan en vivo entre
  sesiones (Supabase Realtime).

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

El acceso a este dashboard ahora depende de que la persona ya esté activa en
**ConkoSafe IA — Alertas DIGEMID**:

1. Que la persona ya tenga cuenta y `acceso_pavs = true` en ese sistema (se
   gestiona desde el panel de usuarios de esa app, o directo en SQL).
2. Si aún no tiene cuenta en la familia de dashboards, que se registre desde
   **Alertas DIGEMID** (https://russali-ux.github.io/Alertas-analyzer/) —
   Corval ya no tiene formulario de registro propio.
3. Con eso, esa misma cuenta (correo/contraseña o Google) ya puede iniciar
   sesión en el panel de Corval.

Para revocar el acceso a Corval específicamente sin quitarle el de Alertas
DIGEMID, se puede usar la política de admin en vez del flag `acceso_pavs`
compartido; por ahora el gate usa directamente `acceso_pavs` porque así lo
pidió el equipo. Un administrador (`rol = 'admin'`) siempre puede ingresar:
```sql
update public.perfiles set rol = 'admin' where email = 'persona@corval.com.pe';
```

> **Nota importante:** `acceso_pavs` viene con valor `true` por defecto para
> cualquier fila nueva de `perfiles` (se crea automáticamente al registrarse
> por primera vez en *cualquier* app de la familia, incluyendo un primer
> inicio de sesión con Google). Es decir, una cuenta de Google totalmente
> nueva que nunca usó Alertas DIGEMID igual pasaría el filtro al ser la
> primera vez que se autentica en el proyecto compartido. Si se quiere que
> el filtro sea 100% estricto (solo cuentas ya existentes y aprobadas
> manualmente en Alertas DIGEMID), hay que cambiar el default de la columna
> `acceso_pavs` a `false` en Supabase — esto afectaría a toda la familia de
> dashboards que usa ese mismo flag, así que no se hizo aquí sin confirmarlo
> con el equipo.

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
