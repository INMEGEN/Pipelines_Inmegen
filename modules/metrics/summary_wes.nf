process summary_wes {
   cache 'lenient'
   container 'pipelinesinmegen/pipelines_inmegen:public'
   publishDir params.out + "/summary_metrics", mode: 'copy'

   input:
   val(list)
   val(project_id)
   path(summary_dir)

   output:
   tuple val(project_id), path("Summary_QCmetrics.txt"), emit: summary_file

   script:
   """
   echo	"Sample id	Depth mean	N alingned reads	N aligned reads on target	N aligned reads on target window 100	On target reads percent	On target reads percent window 100	Total bases(in bed)	N bases on target	Percent of bases on target" >> Summary_QCmetrics.txt

   cat ${summary_dir}/*.txt >> Summary_QCmetrics.txt
   """
}
