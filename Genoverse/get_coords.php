<?php
if (! empty($_POST{'coordStr'}))
{
    $coordStr = $_POST['coordStr'];
 //   global $browse_chr;
 //   global $browse_start;
 //   global $browse_end;

    list ($browse_chr, $browse_start, $browse_end, $error) = parseCoords($coordStr);
    $searched_coords = $browse_chr . ":" . $browse_start . "-" . $browse_end;
    $dat = array(
        "searched_coords" => $searched_coords,
        "chr" => $browse_chr,
        "start"=> $browse_start,
        "end" => $browse_end);
    echo json_encode($dat);
}
?>

<?php
/* This section looks at 'id', 'chr', and 'infile' form data and basically
 * uses php version of grep to select all rows from a gff3 file with the
 * correct chromosome and correct ID and places them in an 'outfile' for 
 * genoverse to read. It is called by clicking the coordinate button in the
 * dataTables table.
 */
if (!empty($_POST{'id'}))
{
    $id = $_POST['id'];
    $chr = $_POST['chr'];
    $stream = new SplFileObject($_POST['infile']);
    $grepped = new RegexIterator($stream, "/^$chr.*$id/");
    $fh = fopen($_POST['outfile'], "w");
    foreach ($grepped as $line){
        fwrite($fh, $line);
    }
    fclose($fh);
}
?>


<?php
function get_ensembl_id($gene_name)
{
    // Use the Ensembl api to get the id for a provided gene name
    // This should work for aliases as well.
    // Return the ID.
    $result =
    file_get_contents('http://rest.ensembl.org/xrefs/symbol/homo_sapiens/'.$gene_name.'?content-type=application/json');
    if ($result) {
        $json = json_decode($result, true);
    } else {
        return "Unknown_gene";
    }
    if(empty($json)){
        return "Unknown_gene";
    }
    return($json[0]['id']);
}
?>

<?php
function get_coords_from_id($id)
{
    // Use the Ensembl API to get the coordinates of a feature
    // when provided with the ID.
    // Returns the coordinates.
    $result =
    file_get_contents('http://rest.ensembl.org/lookup/id/' . $id . '?content-type=application/json');
    if ($result) {
        $json2 = json_decode($result, true);
    } else {
        return "Unknown_id";
    }
    if(empty($json2)){
        return "Unknown_id";
    }
    return($json2);
}
?>

<?php
function parseCoords($coord_str){
    // Parse the coordinate string that is input by the user
    // Accommodates the following formats
    //   chr:num
    //   chr:num-num
    //   geneName
    // All others are unknown
    $coord_str = trim($coord_str);
    $error = "";
    if (preg_match('/^([xyXY0-9]+):([0-9]+)\-*([0-9]*)$/', $coord_str, $coord_array)) {
        // If numeric, with chr:num or chr:num-num
        $input = $coord_array[0];
        $browse_chr = $coord_array[1];
        $browse_start = $coord_array[2];
        if ($coord_array[3]) {
            $browse_end = $coord_array[3];
        } else {
            $browse_start -= 10;
            $browse_end = $browse_start + 20;
        }
    } elseif (preg_match('/^([A-Za-z0-9]+)/', $coord_str, $match_array)){
        $id = get_ensembl_id($coord_str);
        if (preg_match('/Unknown/', $id)) {
            $error = "Unknown gene";
        } else {
            $coords = get_coords_from_id($id);
            if (is_string($coords) && preg_match('/Unknown/', $coords)) {
                $error = "Unknown coordinates for $id";
            }
        }
        $browse_chr   = $coords['seq_region_name'];
        $browse_start = $coords['start'];
        $browse_end   = $coords['end'];
    } else {
        $error = "Unrecognized format";
        // $input = "Unrecognized format";
    }
    return array($browse_chr, $browse_start, $browse_end, $error);
}
?>
