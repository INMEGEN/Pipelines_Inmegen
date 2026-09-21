process fastqc {
  tag "${sample_id}"
  cache 'lenient'
  container 'pipelinesinmegen/pipelines_inmegen:public'
  publishDir params.out + "/fastqc", mode:'copy'
  cpus 2
  memory '4 GB'

  input:
  tuple val(sample), val(sample_id), val(PU), val(PL), val(LB) , path(R1), path(R2)

  output:
  path("${sample_id}/*"), emit: fq_files

  script:
  """
   mkdir -p ${sample_id}

   fastqc -o ${sample_id} -t ${task.cpus} -f fastq -q ${R1} ${R2}
  """
}
