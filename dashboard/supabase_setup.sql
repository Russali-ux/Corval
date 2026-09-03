-- ============================================================
--  CORVAL PHARMACEUTICAL S.A.C. · Configuración de Supabase
--  Ejecuta este script en: Supabase → SQL Editor → New query
--  Proyecto reutilizado: el mismo de Cobefar / PAVS / CIMA / ConkoSafe IA
--  (id de proyecto: ggbnfdaxtsngsjssrwrl). Reutiliza la tabla
--  compartida "perfiles" (ya existente en ese proyecto).
--
--  NOTA: este script YA fue ejecutado por Claude sobre el proyecto
--  ggbnfdaxtsngsjssrwrl al generar este dashboard. Se conserva aquí
--  como documentación y para poder reproducirlo en otro proyecto.
-- ============================================================

-- ---------- 1. Flag de acceso para Corval en "perfiles" ----------
alter table public.perfiles
  add column if not exists acceso_corval boolean not null default true;

comment on column public.perfiles.acceso_corval is
  'Acceso al Dashboard de Farmacovigilancia de Corval (mismo patrón que acceso_cobefar); por defecto true.';

-- ---------- 2. Estados del sistema de FV (árbol de módulos) ----------
create table if not exists public.corval_fv_estados (
  item_id         text primary key,
  status          text not null default 'pending'
                    check (status in ('pending','progress','ok','late')),
  actualizado_por uuid references auth.users(id),
  actualizado_en  timestamptz not null default now()
);

comment on table public.corval_fv_estados is
  'Estado (pendiente/en proceso/al día/vencido) de cada módulo del sistema de FV de Corval Pharmaceutical, mostrado en el panel de control HTML.';

alter table public.corval_fv_estados enable row level security;

create policy "corval_fv_estados_select_autorizado"
  on public.corval_fv_estados for select
  to authenticated
  using (
    exists (select 1 from public.perfiles p
            where p.id = auth.uid() and (p.rol = 'admin' or p.acceso_corval = true))
  );

create policy "corval_fv_estados_upsert_autorizado"
  on public.corval_fv_estados for insert
  to authenticated
  with check (
    exists (select 1 from public.perfiles p
            where p.id = auth.uid() and (p.rol = 'admin' or p.acceso_corval = true))
  );

create policy "corval_fv_estados_update_autorizado"
  on public.corval_fv_estados for update
  to authenticated
  using (
    exists (select 1 from public.perfiles p
            where p.id = auth.uid() and (p.rol = 'admin' or p.acceso_corval = true))
  )
  with check (
    exists (select 1 from public.perfiles p
            where p.id = auth.uid() and (p.rol = 'admin' or p.acceso_corval = true))
  );

alter publication supabase_realtime add table public.corval_fv_estados;

-- ---------- 3. Notificaciones de SRA / evento adverso / calidad ----------
create table if not exists public.corval_notificaciones (
  id                     uuid primary key default gen_random_uuid(),
  codigo_caso            text unique,
  asunto                 text,
  notificador_nombres    text,
  notificador_apellidos  text,
  notificador_email      text,
  notificador_tipo       text,
  paciente_iniciales     text,
  paciente_sexo          text,
  paciente_edad          int,
  telefono               text,
  medicamento            text,
  lote                   text,
  fecha_medicamento      date,
  fecha_evento           date,
  descripcion            text,
  gravedad               text check (gravedad in ('leve','moderada','grave')),
  causalidad             text check (causalidad in ('definida','probable','posible','improbable','condicional','inclasificable')),
  estado_caso            text not null default 'recibido'
                            check (estado_caso in ('recibido','en_evaluacion','en_seguimiento','notificado_anm','cerrado')),
  cerrado_en             timestamptz,
  creado_en              timestamptz not null default now()
);

comment on table public.corval_notificaciones is
  'Notificaciones de sospecha de reacción adversa (SRA), error de medicación o problema de calidad recibidas vía el formulario público de Corval, gestionadas conforme al POE FV-PR002.';

alter table public.corval_notificaciones enable row level security;

-- El formulario público (web de Corval) inserta sin sesión iniciada
create policy "corval_notificaciones_insert_publico"
  on public.corval_notificaciones for insert
  to anon, authenticated
  with check (true);

-- Solo el personal con acceso al módulo Corval (o admin) puede leer/gestionar los casos
create policy "corval_notificaciones_select_autorizado"
  on public.corval_notificaciones for select
  to authenticated
  using (
    exists (select 1 from public.perfiles p
            where p.id = auth.uid() and (p.rol = 'admin' or p.acceso_corval = true))
  );

create policy "corval_notificaciones_update_autorizado"
  on public.corval_notificaciones for update
  to authenticated
  using (
    exists (select 1 from public.perfiles p
            where p.id = auth.uid() and (p.rol = 'admin' or p.acceso_corval = true))
  )
  with check (
    exists (select 1 from public.perfiles p
            where p.id = auth.uid() and (p.rol = 'admin' or p.acceso_corval = true))
  );

alter publication supabase_realtime add table public.corval_notificaciones;

-- ============================================================
--  Para dar acceso al panel a una persona del equipo de Corval
--  (después de que se registre en el modal "Iniciar sesión"):
--
--    update public.perfiles set acceso_corval = true
--    where email = 'persona@corval.com.pe';
--
--  (acceso_corval ya es true por defecto para toda fila nueva de
--  "perfiles", así que en la práctica solo hace falta registrarse).
-- ============================================================
