import os
import csv
from pathlib import Path

def make_map_entrypoint_samplesheet(input_dir, output_csv):
    """
    Generate a samplesheet for nf-core/isoseq v2.0 using merged FASTA files
    from HiFi reads. Sample name is first three dash-separated fields before underscores.

    Also creates individual one-line sample sheets saved in the same directory as output_csv.

    Example:
        CAST-F-striatum_RNA_CCS.merged.fa.gz → sample = CAST-F-striatum
    """
    input_dir = Path(input_dir)
    output_csv = Path(output_csv)
    fasta_files = sorted(input_dir.glob("*.merged.fa.gz"))

    entries = []
    for f in fasta_files:
        sample_id = f.name.split("_")[0]  # CAST-F-striatum from CAST-F-striatum_RNA_CCS...
        fasta_path = str(f.resolve())
        entry = (sample_id, "None", "None", fasta_path)
        entries.append(entry)

        # Write individual sample sheet in same directory as output_csv
        individual_sheet = output_csv.parent / f"{sample_id}_samplesheet.csv"
        with open(individual_sheet, "w", newline='') as ind_f:
            writer = csv.writer(ind_f, delimiter=",")
            writer.writerow(["sample", "bam", "pbi", "reads"])
            writer.writerow(entry)

    if not entries:
        raise ValueError(f"❌ No .merged.fa.gz files found in {input_dir}")

    # Write full samplesheet CSV
    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["sample", "bam", "pbi", "reads"])
        writer.writerows(entries)

    print(f"✅ Joint samplesheet created: {output_csv} ({len(entries)} samples)")
    print(f"📄 Individual sample sheets saved to: {output_csv.parent}")

# Example usage
make_map_entrypoint_samplesheet(
    "/projects/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum/merged/fasta",
    "/projects/csna/sv_ferraj/SVTD/assets/phase1_samplesheet.csv"
)
