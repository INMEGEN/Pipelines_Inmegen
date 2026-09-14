# Pipelines INMEGEN — Desarrollo

Repositorio de trabajo de la **Subdirección de Genómica Poblacional** y la **Subdirección de Bioinformática** del Instituto Nacional de Medicina Genómica.

Aquí se desarrollan y prueban los flujos de análisis antes de integrarse al repositorio de producción [Pipelines_Inmegen](https://github.com/INMEGEN/Pipelines_Inmegen). **Los flujos de esta rama no están validados para uso clínico ni para entrega de servicio.**

## Flujos disponibles

| Flujo | Estado | Descripción |
|---|---|---|
| [VC-Germline](VC-Germline/) | En desarrollo | Identificación conjunta de variantes germinales (WGS/WES) con GATK y DeepVariant, anotación con ANNOVAR, SnpEff y SnpSift |
| Metagenomica | Planeado | — |

Cada flujo tiene su propio `README.md` con las instrucciones de uso y su `RESULTS_INFO.md` con la descripción de los archivos de salida.

## Estructura del repositorio

    .
    ├── modules/                 Procesos de Nextflow, compartidos entre flujos
    │   ├── annotation/          Anotación de variantes (ANNOVAR, SnpEff, SnpSift)
    │   ├── common/              Procesos usados por más de un flujo
    │   ├── metrics/             Métricas de alineamiento, cobertura y variantes
    │   ├── qualitycontrol/      FastQC, Fastq_Screen y MultiQC
    │   └── VC-Germline/         Procesos específicos del flujo germinal
    │
    └── VC-Germline/             Flujo ejecutable
        ├── main.nf              Workflow
        ├── nextflow.config      Configuración de la corrida (NO se versiona)
        ├── sample_info.tsv      Información experimental (NO se versiona)
        ├── run_nextflow.sh      Lanzador del flujo
        ├── bin/                 Recursos y scripts auxiliares
        ├── README.md            Instrucciones de uso
        └── RESULTS_INFO.md      Descripción de los archivos entregados

Un módulo es un archivo `.nf` que define **un solo proceso**. Los módulos no conocen al flujo que los llama: toda la configuración entra por `params`, nunca con rutas escritas en duro.

## Requisitos

- [Nextflow](https://www.nextflow.io/docs/latest/index.html) ≥ 23.04
- [Docker](https://docs.docker.com/) ≥ 23.0.5
- Imagen base del INMEGEN:

      docker pull pipelinesinmegen/pipelines_inmegen:public

Cada flujo puede requerir imágenes y bases de datos adicionales; se indican en su propio `README.md`.

## Cómo correr un flujo

```bash
git clone https://github.com/INMEGEN/Pipelines_Inmegen.git
cd Pipelines_Inmegen/VC-Germline

# Crear la configuración a partir de la plantilla
cp nextflow.config.example nextflow.config
cp sample_info.tsv.example sample_info.tsv

# Editar rutas, referencia y bases de datos
nano nextflow.config
nano sample_info.tsv

# Validar antes de ejecutar
nextflow run main.nf -preview

# Ejecutar
bash run_nextflow.sh
```

`nextflow.config` y `sample_info.tsv` están en `.gitignore` porque son específicos de cada proyecto y servidor. Lo que se versiona son las plantillas `*.example`. Si agregas un parámetro nuevo, actualiza también la plantilla.

## Convenciones

**Ramas**

- `main` — versión estable de desarrollo
- `dev/<flujo>-<tema>` — trabajo en curso, p.ej. `dev/VC-Germline-anotacion`
- Los cambios entran por Pull Request, no directo a `main`

**Nombres**

- Módulos en minúsculas, un proceso por archivo: `haplotypecaller_erc.nf`
- Procesos en *camelCase*: `markDuplicatesSpark`, `fastqScreen`
- Parámetros en *snake_case*: `params.run_deepvariant`, `params.min_dp`

**Qué nunca se sube**

- Archivos de datos: FASTQ, BAM, VCF, índices
- `nextflow.config`, `sample_info.tsv` y cualquier variante con rutas reales
- Logs y directorios de trabajo de Nextflow (`.nextflow*`, `work/`, `out/`)
- Bases de datos de anotación o genomas de referencia

Todo esto está cubierto por el `.gitignore` de la raíz.

**Antes de abrir un Pull Request**

1. `nextflow run main.nf -preview` sin errores
2. Una corrida completa con datos de prueba
3. `README.md` y `RESULTS_INFO.md` del flujo actualizados
4. Plantillas `*.example` al día con los parámetros nuevos

## Agregar un flujo nuevo

1. Crear el directorio del flujo con `main.nf`, `nextflow.config.example`, `sample_info.tsv.example`, `README.md`, `RESULTS_INFO.md`, `run_nextflow.sh` y `bin/`
2. Colocar los procesos en `modules/<flujo>/`, y en `modules/common/`, `modules/metrics/` o `modules/qualitycontrol/` los que se compartan
3. Registrar el flujo en la tabla de este README
4. Trabajar en una rama `dev/<flujo>-<tema>`

## Contacto

- Correo: serviciosbioinfo@inmegen.edu.mx
- Sitio: https://serviciosbio.inmegen.gob.mx/
