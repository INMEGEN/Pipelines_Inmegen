process multiqc {
  cache 'lenient'
  container 'pipelinesinmegen/pipelines_inmegen:public'
  publishDir params.out, mode: 'copy'

  input:
  val(dir_1)
  val(dir_2)
  path(dir_all)

  output:
  path("multiqc/*")   , emit: multiqc_fq_data

  script:
  """
    mkdir -p multiqc

    multiqc -o multiqc/ ${dir_all}
   
    cd multiqc
   
    mv multiqc_report.html QC_report.html    
  """
}

