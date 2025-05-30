// extract_csv.nf

def extract_csv(csv_path) {

    // Check sample sheet has at least 2 lines (header + data)
    def csv_file = new File(csv_path.toString())
    def numberOfLinesInSampleSheet = csv_file.readLines().size()

    if (numberOfLinesInSampleSheet < 2) {
        log.error "Samplesheet had less than two lines. It must have a header and at least one sample row."
        System.exit(1)
    }

    // Parse CSV and return expected fields including shortread_fofn
    return Channel
        .fromPath(csv_path)
        .splitCsv(header: true)
        .map { row ->
            // Check for required columns
            if (!(row.sampleID && row.flnc_bam && row.reference && row.reference_gtf)) {
                log.error "Missing required fields in CSV. Expected columns: sampleID, flnc_bam, reference, reference_gtf, shortread_fofn (optional)."
                System.exit(1)
            }

            def sampleID = row.sampleID.toString()
            def flnc_bam = file(row.flnc_bam.toString())
            def reference = file(row.reference.toString())
            def reference_gtf = file(row.reference_gtf.toString())
            
            // Handle optional shortread_fofn column
            def shortread_fofn = file('NO_FILE') // Default empty file
            if (row.containsKey('shortread_fofn') && row.shortread_fofn && row.shortread_fofn.toString() != 'None' && row.shortread_fofn.toString() != '') {
                shortread_fofn = file(row.shortread_fofn.toString())
                if (!shortread_fofn.exists()) {
                    log.warn "Short read FOFN file not found for ${sampleID}: ${row.shortread_fofn}. Using empty file."
                    shortread_fofn = file('NO_FILE')
                }
            }

            return tuple(sampleID, flnc_bam, reference, reference_gtf, shortread_fofn)
        }
}