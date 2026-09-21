process metricswes {
    tag "${sample_id}"
    cache 'lenient'
    container 'pipelinesinmegen/pipelines_inmegen:public2'
    publishDir params.out + "/metrics", mode: 'copy'
    cpus 4
    memory '12 GB'

    input:
    tuple val(sample_id), path(input_bam), path(bam_idx)
    path(bed_file)
    path(bed_file_w)

    output:
    tuple val(sample_id), path("summary/${sample_id}_QCmetrics.txt"), emit: summary_file
    path("${sample_id}*")

    script:
    """
    mkdir -p summary

    totalcounts=\$(samtools view -q 1 -F 3840 -c ${input_bam})
    onbedcounts=\$(samtools view -q 1 -F 3840 -L ${bed_file} -c ${input_bam})
    onbedcounts2=\$(samtools view -q 1 -F 3840 -L ${bed_file_w} -c ${input_bam})

    ontarget=\$(awk "BEGIN {x=\$totalcounts; if(x==0) print 0; else print \$onbedcounts/x}")
    ontargetp=\$(awk "BEGIN {x=\$ontarget; y=100; print x*y}")
    ontarget2=\$(awk "BEGIN {x=\$totalcounts; if(x==0) print 0; else print \$onbedcounts2/x}")
    ontargetp2=\$(awk "BEGIN {x=\$ontarget2; y=100; print x*y}")

    mosdepth -t ${task.cpus} -b ${bed_file} --thresholds 0,1 ${sample_id} ${input_bam}

    zcat ${sample_id}.thresholds.bed.gz | awk '{print \$(NF-1)"\\t"\$NF}' > ${sample_id}_thresholds.txt

    dpth=\$(grep "total_region" ${sample_id}.mosdepth.summary.txt | awk -F'\\t' '{print \$4"x"}')
    totalbases=\$(awk '{split(\$0,a,"\\t"); sum += a[1]} END {print sum}' ${sample_id}_thresholds.txt)
    ontargetbases=\$(awk '{split(\$0,a,"\\t"); sum += a[2]} END {print sum}' ${sample_id}_thresholds.txt)

    Bontarget=\$(awk "BEGIN {x=\$totalbases; if(x==0) print 0; else print \$ontargetbases/x}")
    Bontargetp=\$(awk "BEGIN {x=\$Bontarget; y=100; print x*y}")

    echo -e "${sample_id}\t\$dpth\t\$totalcounts\t\$onbedcounts\t\$onbedcounts2\t\$ontargetp\t\$ontargetp2\t\$totalbases\t\$ontargetbases\t\$Bontargetp" \
        >> summary/${sample_id}_QCmetrics.txt
    """
}
