<?php
    require_once("../urls/urls.php");
    require_once("formularios/manejar_formulario_expuesto_perinatal.php");
    require_once("../login/utilidades/utilidades.php");
    require_once("../modelos/persona/persona.php");
    require_once("../modelos/persona/datos_antropometricos.php");
    require_once("../modelos/persona/inmunizaciones.php");
    require_once("../modelos/consultas/consulta.php");
    require_once("../modelos/consultas/consulta_expuesto_perinatal.php");
    require_once("../modelos/agendamiento/agendamiento.php");
    require_once("../modelos/persona/datos_servicio.php");
    require_once("../modelos/localidades/establecimiento.php");

    session_start();
    verificarUsuarioLogueado();
    $id_agendamiento = validar_entrada_texto($_GET['id_agendamiento']);
    $agendamiento = Agendamiento::obtenerPorID($id_agendamiento);
		$cod_establecimiento_ultima_consulta = DatosServicio::obtenerCodigoEstablecimientoPorID($agendamiento->id_datos_servicio);
		$establecimiento_ultima_consulta = Establecimiento::obtenerPorCodigoesta($cod_establecimiento_ultima_consulta);
    $id_persona = $agendamiento->id_persona;
    if($id_persona) $persona = Persona::obtenerPersonaPorID($id_persona);
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
      $errores = validarCamposFormularioExpuestoPerinatal();
          if (count($errores) == 0)   {
              manejarCamposFormularioExpuestoPerinatal($id_agendamiento);
              header("Location: " . obtenerUrl("lista_pacientes_agendados"), true, 302);
              exit;
          };
    }   else    {
        $errores = array();
    }
    if($persona->id){
      $inmunizaciones = $persona->obtenerInmunizaciones();
      $ultimos_datos_antropometricos = $persona->obtenerUltimosDatosAntropometricos();
      $tipo_consulta = Consulta::CONSULTA_EXPUESTO_PERINATAL;
      $ultima_consulta = Consulta::obtenerUltimaConsultaPorIdPersona($id_persona);
      if($ultima_consulta->tipo_consulta){
        if($ultima_consulta->tipo_consulta == $tipo_consulta){
          $datos_adicionales = $ultima_consulta->obtenerDatosAdicionalesConsulta();
        } else{
          if(Consulta::obtenerUltimaConsultaPorIdPersonaYTipo($id_persona, $tipo_consulta)){
            $fecha_ultima_consulta = $ultima_consulta->fecha_consulta;
            $cod_reg_ultima_consulta = $ultima_consulta->cod_reg;
            $subcreg_ultima_consulta = $ultima_consulta->subcreg;
            $ultima_consulta = Consulta::obtenerUltimaConsultaPorIdPersonaYTipo($id_persona, $tipo_consulta);
            $ultima_consulta->fecha_consulta = $fecha_ultima_consulta;
            $ultima_consulta->cod_reg = $cod_reg_ultima_consulta;
            $ultima_consulta->subcreg = $subcreg_ultima_consulta;
            $datos_adicionales = $ultima_consulta->obtenerDatosAdicionalesConsulta();  
          }
        }
      }
    }
?>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <title>Consulta Médica</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <?php include("../componentes_navegacion/includes_css_comunes.php");?>
    </head>
    <body class="app header-fixed sidebar-lg-show sidebar-fixed">
        <header class="app-header navbar">
            <?php include("../componentes_navegacion/navbar.php");?>
        </header>
        
        <div class="app-body">
            <?php include("../componentes_html/control_errores.php");?>
            <?php include("../componentes_navegacion/sidebar.php");?>
            
            <main class="main">
                <?php 
                    $nombre_pagina = 'atencion_medica_perinatal'; 
                    include("../componentes_navegacion/breadcrumbs.php");
                ?>
                <div class="container-fluid breadcrumb-push">
                    <div class="animated fadeIn">
                        <?php include("formularios/form_consulta_expuesto_perinatal.php");?>
                    </div>
                </div>
            </main>
        </div>
        
        <?php include("../componentes_navegacion/includes_js_comunes.php");?>

        <!-- Plugins -->
        <script src="https://unpkg.com/gijgo@1.9.13/js/gijgo.js" type="text/javascript"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/gijgo/1.9.13/combined/js/messages/messages.es-es.js" type="text/javascript"></script>
        <!-- Scripts de control -->
        <script src="/sistema_experto/v2/assets/js/forms/comunes.js"></script>
        <script src="/sistema_experto/v2/assets/js/forms/consulta_expuesto_perinatal.js"></script>
        <script src="/sistema_experto/v2/assets/js/campos/campo_buscador_establecimiento.js"></script>
        <script src="/sistema_experto/v2/assets/js/lab/pruebas.js"></script>
        <script src="/sistema_experto/v2/assets/js/forms/solicitud_medicamentos.js"></script>
        <script src="/sistema_experto/v2/assets/js/campos/campo_buscador_cie10.js"></script>
        <script src="/sistema_experto/v2/assets/js/campos/campo_buscador_madre.js"></script>
        <script src="/sistema_experto/v2/assets/js/campos/campo_proxima_consulta.js"></script>
        <script src="/sistema_experto/v2/assets/js/campos/campo_tipo_poblacion.js"></script>

    </body>
</html>
