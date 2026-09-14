process fastqScreen {
  cache 'lenient'
  container 'pipelinesinmegen/pipelines_inmegen:public'
  containerOptions "-v ${params.refdir}:/ref"
  publishDir params.out + "/fastq_screen", mode:'copy'
 
  input: 
  tuple val(sample), path(R1), path(R2)  
  file(config_file)

  output:
  path("${sample}/*"), emit: screen_ch

  script:
  """
   mkdir -p ${sample}
   
   fastq_screen --threads ${params.ncrs} --conf ${config_file} --outdir ${sample} ${R1} ${R2}
  """   
}

