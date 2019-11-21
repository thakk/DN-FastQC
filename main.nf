$HOSTNAME = ""
params.outdir = 'results'  


if (!params.mate_input){params.mate_input = ""} 
if (!params.reads){params.reads = ""} 

Channel.value(params.mate_input).set{g_1_mate_g_0}
Channel
	.fromFilePairs( params.reads , size: (params.mate != "pair") ? 1 : 2 )
	.ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
	.set{g_2_reads_g_0}


params.run_FastQC =  "no"  //* @dropdown @options:"yes","no"



process FastQC {

publishDir params.outdir, overwrite: true, mode: 'copy',
	saveAs: {filename ->
	if (filename =~ /.*.(html|zip)$/) "outputparam/$filename"
}

input:
 val mate from g_1_mate_g_0
 set val(name), file(reads) from g_2_reads_g_0

output:
 file '*.{html,zip}'  into g_0_FastQCout

errorStrategy 'retry'
maxRetries 3

when:
(params.run_FastQC && (params.run_FastQC == "yes"))

script:
nameAll = reads.toString()
if (nameAll.contains('.gz')) {
    file =  nameAll - '.gz' - '.gz'
    runGzip = "ls *.gz | xargs -i echo gzip -df {} | sh"
} else {
    file =  nameAll 
    runGzip = ''
}
"""
${runGzip}
fastqc ${file} 
"""
}


workflow.onComplete {
println "##Pipeline execution summary##"
println "---------------------------"
println "##Completed at: $workflow.complete"
println "##Duration: ${workflow.duration}"
println "##Success: ${workflow.success ? 'OK' : 'failed' }"
println "##Exit status: ${workflow.exitStatus}"
}
