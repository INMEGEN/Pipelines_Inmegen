process fastqc {
  cache 'lenient'
  container 'pipelinesinmegen/pipelines_inmegen:public'
  publishDir params.out + "/fastqc", mode:'copy'
 
  input: 
  tuple val(sample), val(sample_id), val(PU), val(PL), val(LB) , path(R1), path(R2)  
  
  output:
  path("${sample_id}/*"), emit: fq_files

  script:
  """
   mkdir -p ${sample_id}

   fastqc -o ${sample_id} -t ${params.ncrs} -f fastq -q ${R1} ${R2}
  """   
}

