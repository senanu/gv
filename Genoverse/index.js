$(document).ready(function() {
    $("#search_form").submit(function(event) {
        var coordStr = $("input#coords").val();
	get_coords(coordStr);
    });

    // See if the URL contains a gene. If so, convert it to coords
    try{
        var gene = get_URL_gene();
        if(typeof(gene) !== "undefined"){
            get_coords(gene);
        }
    }
    catch(err){} // don't worry if there's an error: no gene is listed

    // Append the coordinates to the div with "current display" and "last query"
    var coords = get_URL_coordParts('r', 'full');
    $('#actual_coords').append(coords);
    var query_coords = get_URL_coordParts('last_query', 'full');
    $('#query_coords').append(query_coords);

    var this_last_query = get_URL_coordParts('last_query', 'chr');
    if (typeof this_last_query !== 'undefined'){
        data_url = "chromosome_" + this_last_query + ".json";
        //myTable.ajax.url(data_url).load();
    }
    return false;
});


function get_URL_vars() {
	var get_var = {};
	var parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function (i, key, value) {
		get_var[key] = value;
	});
	return get_var;
}

function get_URL_gene(){
    var this_get_var = get_URL_vars();
    var gene = this_get_var['gene'];
    return gene;
}

function get_coords(gene){
    $.ajax({
	type: "POST",
	url:  "get_coords.php",
	data: {coordStr: gene},
	success: function(data){
	    browse_chr   = JSON.parse(data).chr;
	    browse_start = JSON.parse(data).start;
	    browse_end   = JSON.parse(data).end;
	    var goto_coord = browse_chr + ":" + browse_start + "-" + browse_end;
            window.location.href = "index.html?r=" + goto_coord + "&last_query=" + goto_coord;
        }
    });
    event.preventDefault();
    return false;
}
/**
 * Get the coordinates as a string as represented on the URL
 * @return {string} Coordinates as a string.
 */
function get_URL_coords(){
    var this_get_var = get_URL_vars();
    var coord_str = this_get_var['r'];
    return coord_str;
}
/**
 * Get the last query coordinates as recorded into the URL
 * @param  {string} time a string either 'r' for the current coordinate location
 * or 'last_query' for the coords resulting from the last query. 'last_query'
 * is more historic than 'r', which is what is currently shown.
 * @param  {string} part a string indicating which part of the
 * coordinate string is desired. Possible values: 'full'=full string with
 * chr:start-end, 'chr'=chromosome, 'start'=start coordinate,
 * 'end'=end coordinate
 * @return {string} String Either the full coordinate string, the chromosome number,
 * start, or end. Null is returned if the parameter is none of those
 * specified above.     [description]
 */
function get_URL_coordParts(time, part){
    var this_get_var = get_URL_vars();
    var full_coords = this_get_var[time];
    var re = /([0-9XY]+)\:([0-9]+)\-([0-9]+)/;
    var matches = re.exec(full_coords);
    if(part === 'full'){
        return matches[0];
    } else if (part === 'chr'){
        return matches[1];
    } else if (part === 'start'){
        return matches[2];
    } else if (part === 'end'){
        return matches[3];
    } else {
        return null ;
    }
}

$(function() {
    new Genoverse({
        genome    : 'grch38', // see js/genomes/
        chr       : chr_num,
        start     : 100000,
        end       : 100100,
        highlights : [{start     : get_URL_coordParts('last_query', 'start'),
                       end       : get_URL_coordParts('last_query', 'end'),
                       label     : "Last Query Position",
                       removable : 1}],
        plugins   : [ 'controlPanel', 'karyotype', 'trackControls', 'resizer', 'focusRegion', 'fullscreen', 'tooltips', 'fileDrop' ],
        tracks    : [
            Genoverse.Track.Scalebar,
            Genoverse.Track.extend({
                name       : 'Sequence',
                controller : Genoverse.Track.Controller.Sequence,
                model      : Genoverse.Track.Model.Sequence.Ensembl,
                view       : Genoverse.Track.View.Sequence,
                100000     : false,
                resizable  : 'auto'
            }),
            Genoverse.Track.Gene,
            Genoverse.Track.extend({
                name            : 'Ensembl Regulatory Features',
                url             : 'http://rest.ensembl.org/overlap/region/human/__CHR__:__START__-__END__?feature=regulatory;content-type=application/json',
                resizable       : 'auto',
                model           : Genoverse.Track.Model.extend({ dataRequestLimit : 5000000 }),
                setFeatureColor : function (f) {
                    f.color = '#AAA';
                }
            }),
            Genoverse.Track.extend({
                name            : 'AutDB: Human Gene Module',
                id              : 'Human Gene Module',
                url             : '../Genoverse_Data/SNP_' + get_URL_coordParts('r', 'chr') + '.json',
                resizable       : 'auto',
                model           : Genoverse.Track.Model.extend(),
                view            : Genoverse.Track.View.Gene,
                featureHeight   : 10,
                legend          : true,
                colorMap        : colors,
                constructor: function () {
                    this.base.apply(this, arguments);
                    if (this.legend === true) {
                        this.addLegend();
                    }
                },
                insertFeature: function (feature) {
                    feature.color  = this.prop('colorMap')[feature.Mutation_Type_Details];
                    feature.legend = feature.Mutation_Type_Details;
                    this.base(feature);
                }
            }),
            Genoverse.Track.extend({
                name            : 'AutDB: CNVs',
                id              : 'CNV',
                url             : '../Genoverse_Data/CNV_' + get_URL_coordParts('r', 'chr') + '.json',
                resizable       : 'auto',
                labels          : true,
                legend          : true,
                model           : Genoverse.Track.Model.extend(),
                view            : Genoverse.Track.View.Gene,
                colorMap        : colors,
                constructor: function () { // Add a legend
                    this.base.apply(this, arguments);
                    if (this.legend === true) {
                        this.addLegend();
                    }
                },
                insertFeature: function (feature) { // Add colors
                    feature.color  = this.prop('colorMap')[feature.CNV_type];
                    feature.legend = feature.CNV_type;
                    this.base(feature);
                }
            }),

            Genoverse.Track.dbSNP,
        ]
    });
});

var colors = {
    '2KB_upstream_variant'                           : '#7ac5cd',
    '2KB_upstream_variant, 5_prime_UTR_variant'      : '#7ac5cd',
    '3_prime_UTR_variant'                            : '#7ac5cd',
    '5KB_upstream_variant'                           : '#7ac5cd',
    '5_prime_UTR_variant'                            : '#7ac5cd',
    'copy_number_gain'                               : '#406000',
    'copy_number_loss'                               : '#606080',
    'frameshift_variant'                             : '#9400D3',
    'frameshift_variant;frameshift_variant'          : '#9400D3',
    'inframe_deletion'                               : '#ff69b4',
    'inframe_deletion;inframe_deletion'              : '#ff69b4',
    'inframe_insertion'                              : '#ff69b4',
    'initiator_codon_variant'                        : '#32cd32',
    'intron_variant'                                 : '#02599c',
    'inversion'                                      : '#458b00',
    'missense_variant'                               : '#ffd700',
    'missense_variant;missense_variant'              : '#ffd700',
    'nonsynonymous_variant'                          : '#FF0080',
    'splice_site_variant'                            : '#FF581A',
    'splice_site_variant, 3_prime_UTR_variant'       : '#FF581A',
    'splice_site_variant;splice_site_variant'        : '#FF581A',
    'stop_gained'                                    : '#ff0000',
    'stop_gained;stop_gained'                        : '#ff0000',
    'synonymous_variant'                             : '#76ee00',
    'translocation'                                  : '#458b00',
    'trinucleotide_repeat_microsatellite_feature'    : '#7f7f7f',
    'trinucleotide_repeat_microsatellite_feature, 5_prime_UTR_variant' : '#7f7f7f',
    'Complex'                                        : '#669900',
    'Deletion'                                       : '#FF0000',
    'Duplication'                                    : '#0033CC',
    'Duplication (mosaic)'                           : '#001F7D',
    'Homozygous deletion'                            : '#800000',
    'Homozygous duplication'                         : '#8080FF',
    'Mosaic deletion'                                : '#330000',
    'N/A'                                            : '#000D1A',
    'NA'                                             : '#000D1A',
    'Triplication'                                   : '#003B00',
    'Unknown'                                        : '#000D1A',
    'complex'                                        : '#669900'
};
