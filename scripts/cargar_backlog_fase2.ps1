# cargar_backlog_fase2.ps1
# Agrega al tablero "Kanban - Carnicería La Feria (AS2 Fase 1)" (GitHub Projects N.º 1):
#   1. Los campos Tipo, Prioridad, Puntos y Sprint.
#   2. Las 19 historias de usuario del Product Backlog, con prioridad, puntos y sprint.
#   3. Las tareas del equipo para la Fase 2 (Bitácora N.º 3) y la actualización de las de la Fase 1.
#
# Requisitos: GitHub CLI con sesión iniciada y permiso de Projects (ya configurado en la Fase 1).
# Uso (en la carpeta donde está este archivo):
#   powershell -ExecutionPolicy Bypass -File .\cargar_backlog_fase2.ps1
# Se puede ejecutar más de una vez: no duplica campos ni tarjetas que ya existan.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Owner = 'JosephOrtiz'
$Num   = 1

function Test-Gh([string]$paso) {
    if ($LASTEXITCODE -ne 0) { throw "Falló el paso: $paso. Revise el mensaje de error de gh." }
}

function Get-Fields {
    $json = gh project field-list $Num --owner $Owner --format json --limit 100
    Test-Gh 'leer los campos'
    return (($json -join "`n") | ConvertFrom-Json).fields
}

function Get-Items {
    $json = gh project item-list $Num --owner $Owner --format json --limit 500
    Test-Gh 'leer las tarjetas'
    return (($json -join "`n") | ConvertFrom-Json).items
}

Write-Host '1/5 Leyendo el tablero...' -ForegroundColor Cyan
$json = gh project view $Num --owner $Owner --format json
Test-Gh 'leer el proyecto'
$proyecto = ($json -join "`n") | ConvertFrom-Json
$projId = $proyecto.id

Write-Host '2/5 Creando los campos que falten...' -ForegroundColor Cyan
$campos = Get-Fields
$nombres = $campos | ForEach-Object { $_.name }
if ($nombres -notcontains 'Tipo') {
    gh project field-create $Num --owner $Owner --name 'Tipo' --data-type SINGLE_SELECT --single-select-options 'Historia de usuario,Tarea del equipo' | Out-Null
    Test-Gh 'crear el campo Tipo'
}
if ($nombres -notcontains 'Prioridad') {
    gh project field-create $Num --owner $Owner --name 'Prioridad' --data-type SINGLE_SELECT --single-select-options 'Must,Should,Could' | Out-Null
    Test-Gh 'crear el campo Prioridad'
}
if ($nombres -notcontains 'Puntos') {
    gh project field-create $Num --owner $Owner --name 'Puntos' --data-type NUMBER | Out-Null
    Test-Gh 'crear el campo Puntos'
}
if ($nombres -notcontains 'Sprint') {
    gh project field-create $Num --owner $Owner --name 'Sprint' --data-type SINGLE_SELECT --single-select-options 'Sprint 1,Sprint 2,Sprint 3,Sprint 4' | Out-Null
    Test-Gh 'crear el campo Sprint'
}

$campos  = Get-Fields
$f = @{}
foreach ($c in $campos) { $f[$c.name] = $c }
function OptId([string]$campo, [string]$valor) {
    $o = $f[$campo].options | Where-Object { $_.name -eq $valor }
    if (-not $o) { throw "No existe la opción '$valor' en el campo '$campo'." }
    return $o.id
}
function Set-Select($itemId, [string]$campo, [string]$valor) {
    gh project item-edit --id $itemId --project-id $projId --field-id $f[$campo].id --single-select-option-id (OptId $campo $valor) | Out-Null
    Test-Gh "asignar $campo"
}
function Set-Text($itemId, [string]$campo, [string]$valor) {
    gh project item-edit --id $itemId --project-id $projId --field-id $f[$campo].id --text $valor | Out-Null
    Test-Gh "asignar $campo"
}
function Set-Date($itemId, [string]$campo, [string]$valor) {
    gh project item-edit --id $itemId --project-id $projId --field-id $f[$campo].id --date $valor | Out-Null
    Test-Gh "asignar $campo"
}
function Set-Number($itemId, [string]$campo, $valor) {
    gh project item-edit --id $itemId --project-id $projId --field-id $f[$campo].id --number $valor | Out-Null
    Test-Gh "asignar $campo"
}
function New-Card([string]$titulo, [string]$cuerpo) {
    $json = gh project item-create $Num --owner $Owner --title $titulo --body $cuerpo --format json
    Test-Gh "crear la tarjeta '$titulo'"
    return (($json -join "`n") | ConvertFrom-Json).id
}

$items = Get-Items
$porTitulo = @{}
foreach ($i in $items) {
    $t = $i.title
    if (-not $t -and $i.content) { $t = $i.content.title }
    if ($t) { $porTitulo[$t] = $i.id }
}

Write-Host '3/5 Actualizando las tareas de la Fase 1...' -ForegroundColor Cyan
foreach ($t in @($porTitulo.Keys)) { Set-Select $porTitulo[$t] 'Tipo' 'Tarea del equipo' }
foreach ($t in @('Presentación de la Fase 1', 'Carga final de la documentación al repositorio Git', 'Entrega de la Fase 1 en e-campus (PDF)')) {
    if ($porTitulo.ContainsKey($t)) { Set-Select $porTitulo[$t] 'Estado' 'Terminado'; Write-Host "   OK  [Terminado] $t" }
}

Write-Host '4/5 Tareas del equipo para la Fase 2 (Bitácora N.º 3)...' -ForegroundColor Cyan
# Título, Responsable, Fecha (AAAA-MM-DD), Estado
$Tareas = @(
    @('Bitácora N.º 3 (inicio de la Fase 2)',                          'Josseph Ortiz Navarro',       '2026-11-19', 'Terminado'),
    @('Actualizar el tablero Kanban con la Fase 2',                    'Fernanda Rodríguez Alvarado', '2026-11-20', 'Terminado'),
    @('Corrección del alcance de la solución',                         'Rebeca Morales Tijerino',     '2026-11-22', 'Pendiente'),
    @('RFC de un cambio real (Fase 2)',                                'Nicole Sánchez Gómez',        '2026-11-23', 'En proceso'),
    @('Sesión de Planning Poker del equipo',                           'Todo el equipo',              '2026-11-23', 'Pendiente'),
    @('Backlog priorizado y planificación de sprints (Fase 2)',        'Fernanda Rodríguez Alvarado', '2026-11-25', 'En proceso'),
    @('Estimación con Planning Poker y PERT (Fase 2)',                 'Fernanda Rodríguez Alvarado', '2026-11-25', 'En proceso'),
    @('Diagramas UML: casos de uso, secuencia y actividades',          'Nicole Sánchez Gómez',        '2026-11-26', 'Pendiente'),
    @('Diagrama de clases',                                            'Josseph Ortiz Navarro',       '2026-11-26', 'Pendiente'),
    @('Modelo entidad-relación y diccionario de datos (Fase 2)',       'Josseph Ortiz Navarro',       '2026-11-26', 'Pendiente'),
    @('Firma de las bitácoras N.º 1 y N.º 2',                          'Todo el equipo',              '2026-11-26', 'Pendiente'),
    @('Mockups de los 3 módulos principales (Fase 2)',                 'Rebeca Morales Tijerino',     '2026-11-27', 'Pendiente'),
    @('Integración del documento de la Fase 2',                        'Todo el equipo',              '2026-11-30', 'Pendiente'),
    @('Presentación de la Fase 2',                                     'Todo el equipo',              '2026-12-01', 'Pendiente'),
    @('Bitácora N.º 4 (cierre de la Fase 2)',                          'Josseph Ortiz Navarro',       '2026-12-01', 'Pendiente'),
    @('Entrega de la Fase 2 en e-campus (PDF)',                        'Josseph Ortiz Navarro',       '2026-12-03', 'Pendiente')
)
foreach ($t in $Tareas) {
    if ($porTitulo.ContainsKey($t[0])) {
        $id = $porTitulo[$t[0]]
    } else {
        $id = New-Card $t[0] "Responsable: $($t[1]). Fecha de entrega: $($t[2]). Fase 2."
        $porTitulo[$t[0]] = $id
    }
    Set-Select $id 'Tipo' 'Tarea del equipo'
    Set-Select $id 'Estado' $t[3]
    Set-Text   $id 'Responsable' $t[1]
    Set-Date   $id 'Fecha de entrega' $t[2]
    Write-Host "   OK  [$($t[3])] $($t[0])"
}

Write-Host '5/5 Product Backlog: 19 historias de usuario...' -ForegroundColor Cyan
# Título, Descripción, Prioridad, Puntos, Sprint
$Historias = @(
    @('HU-12 Usuarios y permisos', 'Como dueño, quiero que cada usuario tenga su propia cuenta y permisos, para proteger la información del negocio. Módulo: Usuarios. Origen: Fase 1 (ajustada por RFC-001). Orden en el backlog: 1.', 'Must', 8, 'Sprint 1'),
    @('HU-01 Registrar productos', 'Como dueño, quiero registrar los productos que vendo, para tener un catálogo con precios y existencias. Módulo: Inventario. Origen: Fase 1. Orden en el backlog: 2.', 'Must', 3, 'Sprint 1'),
    @('HU-02 Consultar existencias', 'Como dueño, quiero ver la existencia actual de cada producto, para saber qué debo pedir. Módulo: Inventario. Origen: Fase 1. Orden en el backlog: 3.', 'Must', 2, 'Sprint 1'),
    @('HU-13 Registrar clientes con crédito', 'Como dueño, quiero registrar a los clientes con crédito, para no confundir clientes con nombres iguales. Módulo: Cuentas por cobrar. Origen: Fase 1 (ajustada por RFC-001). Orden en el backlog: 4.', 'Must', 3, 'Sprint 1'),
    @('HU-15 Registrar consentimiento', 'Como dueño, quiero registrar el consentimiento del cliente al abrir su cuenta de crédito, para proteger sus datos personales. Módulo: Cuentas por cobrar. Origen: RFC-001. Orden en el backlog: 5.', 'Must', 3, 'Sprint 1'),
    @('HU-04 Registrar proveedores', 'Como encargado de compras, quiero registrar a los proveedores, para tener sus datos en un solo lugar. Módulo: Pedidos. Origen: Fase 1. Orden en el backlog: 6.', 'Should', 2, 'Sprint 1'),
    @('HU-14 Ajustes de inventario', 'Como dueño, quiero registrar ajustes de inventario por merma o vencimiento, para que las existencias reflejen la realidad y conocer las pérdidas. Módulo: Inventario. Origen: Fase 1. Orden en el backlog: 7.', 'Should', 3, 'Sprint 1'),
    @('HU-07 Registrar ventas', 'Como cajero, quiero registrar cada venta, para saber qué se vendió y mantener actualizado el inventario. Módulo: Ventas. Origen: Fase 1. Orden en el backlog: 8.', 'Must', 8, 'Sprint 2'),
    @('HU-08 Registrar venta a crédito', 'Como cajero, quiero registrar una venta a crédito a un cliente, para no anotarla en el cuaderno. Módulo: Cuentas por cobrar. Origen: Fase 1. Orden en el backlog: 9.', 'Must', 5, 'Sprint 2'),
    @('HU-09 Registrar abonos', 'Como dueño, quiero registrar los abonos de un cliente, para saber cuánto me debe. Módulo: Cuentas por cobrar. Origen: Fase 1. Orden en el backlog: 10.', 'Must', 3, 'Sprint 2'),
    @('HU-03 Alerta de existencia mínima', 'Como dueño, quiero recibir una alerta cuando un producto llegue a su mínimo, para no quedarme sin producto. Módulo: Inventario. Origen: Fase 1. Orden en el backlog: 11.', 'Should', 3, 'Sprint 2'),
    @('HU-16 Estado de cuenta del cliente', 'Como dueño, quiero generar el estado de cuenta de un cliente, para mostrarle sus compras, abonos y saldo cuando lo pida. Módulo: Cuentas por cobrar. Origen: RFC-001. Orden en el backlog: 12.', 'Should', 3, 'Sprint 2'),
    @('HU-05 Registrar pedidos', 'Como encargado de compras, quiero registrar cada pedido a un proveedor, para tener respaldo de lo que solicité. Módulo: Pedidos. Origen: Fase 1. Orden en el backlog: 13.', 'Should', 5, 'Sprint 3'),
    @('HU-06 Registrar recepción y diferencias', 'Como encargado de compras, quiero registrar lo que recibo, para detectar diferencias con lo pedido. Módulo: Pedidos. Origen: Fase 1. Orden en el backlog: 14.', 'Should', 8, 'Sprint 3'),
    @('HU-18 Bitácora de cambios', 'Como dueño, quiero consultar una bitácora de cambios, para saber quién modificó ventas, saldos, precios o inventario. Módulo: Usuarios. Origen: RFC-001. Orden en el backlog: 15.', 'Should', 5, 'Sprint 3'),
    @('HU-19 Anular ventas y abonos', 'Como dueño, quiero anular una venta o un abono indicando el motivo, para corregir errores sin borrar el registro. Módulo: Ventas. Origen: RFC-001. Orden en el backlog: 16.', 'Should', 5, 'Sprint 3'),
    @('HU-10 Reporte de ventas', 'Como dueño, quiero ver un reporte de ventas por día y por mes, para conocer cuánto y qué se vende en el negocio. Módulo: Reportes. Origen: Fase 1. Orden en el backlog: 17.', 'Could', 5, 'Sprint 4'),
    @('HU-11 Reporte de proveedores', 'Como dueño, quiero ver un reporte de cumplimiento de proveedores, para decidir con quién seguir trabajando. Módulo: Reportes. Origen: Fase 1. Orden en el backlog: 18.', 'Could', 5, 'Sprint 4'),
    @('HU-17 Corregir o anonimizar datos del cliente', 'Como dueño, quiero corregir o anonimizar los datos de un cliente cuando lo solicite, para atender sus derechos sin perder el historial de ventas. Módulo: Cuentas por cobrar. Origen: RFC-001. Orden en el backlog: 19.', 'Could', 5, 'Sprint 4')
)
foreach ($h in $Historias) {
    if ($porTitulo.ContainsKey($h[0])) {
        $id = $porTitulo[$h[0]]
    } else {
        $id = New-Card $h[0] $h[1]
        $porTitulo[$h[0]] = $id
    }
    Set-Select $id 'Tipo' 'Historia de usuario'
    Set-Select $id 'Estado' 'Pendiente'
    Set-Select $id 'Prioridad' $h[2]
    Set-Number $id 'Puntos' $h[3]
    Set-Select $id 'Sprint' $h[4]
    Write-Host "   OK  [$($h[4]) | $($h[2]) | $($h[3]) pts] $($h[0])"
}

Write-Host ''
Write-Host "Listo. Tablero: $($proyecto.url)" -ForegroundColor Green
Write-Host ''
Write-Host 'Vistas sugeridas (se crean en el navegador, botón "New view"):'
Write-Host '  1) "Product Backlog": diseño Table, filtro  Tipo:"Historia de usuario", agrupar por Sprint,'
Write-Host '     mostrar Prioridad, Puntos y Sprint, y activar la suma de Puntos (menú de la columna Puntos).'
Write-Host '  2) "Tareas del equipo": diseño Board, filtro  Tipo:"Tarea del equipo", Column by: Estado.'
Write-Host 'Tome una captura de cada vista para el documento (Windows + Shift + S).'
