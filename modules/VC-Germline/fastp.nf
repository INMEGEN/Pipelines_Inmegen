process fastp {
  cache 'lenient'
  container 'pipelinesinmegen/pipelines_inmegen:public'
  publishDir params.out + "/trimmed_files", mode: 'symlink'

  input:
  tuple val(sample), val(sample_id), val(PU), val(PL), val(LB), path(R1), path(R2)
  path(adapters)

  output:
  tuple val(sample), val(sample_id), val(PU), val(PL), val(LB), path("${sample_id}_R1.trimmed.fq.gz"), path("${sample_id}_R2.trimmed.fq.gz"), emit: trim_fq
  tuple path("${sample_id}_fastp.html"), path("${sample_id}_fastp.json")

  script:
  """
  fastp --in1 ${R1} --in2 ${R2} --out1 ${sample_id}_R1.trimmed.fq.gz --out2 ${sample_id}_R2.trimmed.fq.gz \
         --adapter_fasta ${adapters} --detect_adapter_for_pe -g --poly_g_min_len 9 -q 20 -l 50 \
         -h ${sample_id}_fastp.html -j ${sample_id}_fastp.json
  """
}
