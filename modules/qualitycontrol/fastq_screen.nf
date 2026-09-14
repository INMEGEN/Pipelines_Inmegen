process fastqScreen {
  tag "${sample}"
  cache 'lenient'
  container 'pipelinesinmegen/pipelines_inmegen:public'
  containerOptions "-v ${params.fqscreen_db}:/fqscreen_db"
  publishDir params.out + "/fastq_screen", mode:'copy'

  input:
  tuple val(sample), path(R1), path(R2)
  file(config_file)

  output:
  path("${sample}/*"), emit: screen_ch

  script:

  // Los genomas se montan en /fqscreen_db, el archivo .conf DEBE usar esa ruta.
  // --subset: número de lecturas muestreadas por archivo (0 = todas).

  """
   mkdir -p ${sample}

   fastq_screen --threads ${params.ncrs} \
                --aligner ${params.fqscreen_aligner} \
                --subset ${params.fqscreen_subset} \
                --conf ${config_file} \
                --outdir ${sample} ${R1} ${R2}
  """
}
