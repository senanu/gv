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



$(document).ready(function() {
    myTable = $('#data_table').DataTable( {
        stateSave: true,
        ajax: {
            url: data_url,
            dataSrc: ''
        },
        columns: [
            { "data": "id"},
            { "data": "seq_region_name" },
            { "data": "start" },
            { "data": "end" },
            { "data": "bases_unmapped" },
            { "data": "start_end_mapped" },
            { "data": "regions"},
            {
                "className":      'details-control',
                "orderable":      false,
                "data":           null,
                "defaultContent": ''
            }
        ],
        columnDefs: [
            {
                targets: [1],
                render: function ( data, type, row, meta)
                {
                    coord_str = data + ':' + row["start"] + '-' + row["end"];
                    return("<button>" + coord_str + "</button>");
                }
            },
            {
                targets: [2,3],
                visible: false
            }

        ],
        scrollY: 200,
        deferRender: true,
        scroller: true
    } );
    $('#filt_lastquery').change( function(event){
        myTable.draw();
    });
    $('#filt_range').change( function(event){
        myTable.draw();
    });
    $('#filt_imperfect').change( function(event){
        myTable.draw();
    });
     // Add event listener for opening and closing details
    $('#data_table tbody').on('click', 'td.details-control', function () {
        var tr = $(this).closest('tr');
        var row = myTable.row( tr );
        alert(format(row.data()));
        /* The following code is for using child rows but there is too much
         * data so instead we just use a simple alert with pre-formatted text.
         *if ( row.child.isShown() ) {
            // This row is already open - close it
            row.child.hide();
            tr.removeClass('shown');
        }
        else {
            // Open this row
            row.child( format(row.data()) ).show();
            tr.addClass('shown');
        }*/
    } );
    $('#data_table tbody').on( 'click', 'button', function () {
        var data = myTable.row( $(this).parents('tr') ).data();
        var last_query = get_URL_coordParts('last_query', 'full');
        var goto_coord = data["seq_region_name"] + ":" + data["start"] + "-" + data["end"];
        $.ajax({
            type: "POST",
            url: 'get_coords.php',
            data: {id: data["id"],
                chr: data["seq_region_name"],
                infile: 'chr_' + data["seq_region_name"] + '.gff3',
                outfile: "regions.gff3"},
            success: function(data){
                //alert(data);
            },
            error: function(){
                //alert("OH NO!!! Please try clicking that button again -- the server didn't have time to create the necessary file");
            }
        });
        window.location.href = "index.html?r=" + goto_coord + "&last_query=" + last_query;
    } );
} );

/*Function to format the child rows of the table
 * This is currently not being used because there is too much
 * data to fit conveniently*/
function format2 ( d ) {
    // `d` is the original data object for the row
    return '<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">'+
        '<tr>'+
            '<td>details:</td>'+
            '<td>'+d+'</td>'+
        '</tr>'+
        '<tr>'+
            '<td>Extension number:</td>'+
            '<td>'+d.start+'</td>'+
        '</tr>'+
        '<tr>'+
            '<td>Extra info:</td>'+
            '<td>And any further details here (images etc)...</td>'+
        '</tr>'+
    '</table>';
}

function format (d) {
    //'d' is the original data object for the row
    var str = JSON.stringify(d, null, '\t');
    return str;
}
//These functions are used to pre-load the "Tabular display" with the last chromosomal search
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


/* Custom filtering function by last query for the datatable*/
$.fn.dataTable.ext.search.push(
    function( settings, data, dataIndex) {
        var filt_criteria;
        if ( $('#filt_lastquery:checked').val() === 'on'){
            filt_criteria = get_URL_coordParts('last_query', 'full');
        } else {
            filt_criteria = '';
        }
        criteria_array = filt_criteria.split(/[\:-]/);
        var chr   = parseInt(data["1"], 10);
        var start = parseInt(data["2"], 10);
        var end   = parseInt(data["3"], 10);
        if( ( filt_criteria === '')  ||
                ( filt_criteria === null) ||
            ( criteria_array[1] <= start && criteria_array[2] >= start ) ||
            ( criteria_array[1] <= end   && criteria_array[2] >= end   ) ||
            ( criteria_array[1] >= start && criteria_array[2] <= end  )) {
            return true;
        }
        return false;
    }
);

/* Custom filtering function by user-editable location for the datatable*/
$.fn.dataTable.ext.search.push(
    function( settings, data, dataIndex) {
        var filt_criteria = $('#filt_range').val();
        criteria_array = filt_criteria.split(/[\:-]/);
        var chr   = parseInt(data["1"], 10);
        var start = parseInt(data["2"], 10);
        var end   = parseInt(data["3"], 10);
        if( ( filt_criteria === '')  ||
                ( filt_criteria === null) ||
            ( criteria_array[1] <= start && criteria_array[2] >= start ) ||
            ( criteria_array[1] <= end   && criteria_array[2] >= end   ) ||
            ( criteria_array[1] >= start && criteria_array[2] <= end   )  ) {
            return true;
        }
        return false;
    }
);

/* Custom filtering function by imperfect mapping for the datatable*/
$.fn.dataTable.ext.search.push(
    function( settings, data, dataIndex) {
        var restrict_to_imperfect;
        if ( $('#filt_imperfect:checked').val() === "on"){
            restrict_to_imperfect = true;
        } else {
            restrict_to_imperfect = false;
        }
        var unmapped   = parseInt(data["4"], 10);
        var start_end  = data["5"];
        var regions    = parseInt(data["6"], 10);
        if( restrict_to_imperfect === false ){
            return true;
        } else if ( ( unmapped  !== 0)  ||
                ( start_end !== 'Both') ||
                ( regions   !== 1 ) ){
            return true;
        }
        return false;
    }
);

genoverseConfig = {
    container : '#genoverse', // Where to inject Genoverse (css/jQuery selector)
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
      //  Genoverse.Track.extend({
      //      name            : 'Variant from Table',
      //      url             : 'CNV_GRCH38.gff3',
      //      resizable       : 'auto',
      //      model           : Genoverse.Track.Model.Transcript.GFF3,
      //      view            : Genoverse.Track.View.Transcript
      //  }),
      Genoverse.Track.extend({
            name            : 'Variant from Table',
            url             : 'regions.gff3',
            resizable       : 'auto',
            model           : Genoverse.Track.Model.Transcript.GFF3,
            view            : Genoverse.Track.View.Transcript
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
            name            : 'AutDB: SNPs and small indels',
            id              : 'Small Variants',
            url             : '../Genoverse_Data/SNP_' + get_URL_coordParts('r', 'chr') + '.json',
            resizable       : 'auto',
            model           : Genoverse.Track.Model.extend(),
            view            : Genoverse.Track.View.Gene,
            featureHeight   : 10,
            legend          : true,

            colorMap         : {
                '2KB_upstream_variant'                           : '#7ac5cd',
                '2KB_upstream_variant, 5_prime_UTR_variant'      : '#7ac5cd',
                '3_prime_UTR_variant'                            : '#7ac5cd',
                '5KB_upstream_variant'                           : '#7ac5cd',
                '5_prime_UTR_variant'                            : '#7ac5cd',
                'copy_number_gain'                               : '#406000',
                'copy_number_loss'                               : '#606080',
                'frameshift_variant'                             : '#9400D3',
                'frameshift_variant;frameshift_variant'          : '#9400D3',
                'inframe_deletion'                               : '#606080',
                'inframe_deletion;inframe_deletion'              : '#606080',
                'inframe_insertion'                              : '#406000',
                'initiator_codon_variant'                        : '#32cd32',
                'intron_variant'                                 : '#02599c',
                'inversion'                                      : '#458b00',
                'missense_variant'                               : '#ff69b4',
                'missense_variant;missense_variant'              : '#ff69b4',
                'nonsynonymous_variant'                          : '#ff69b4',
                'splice_site_variant'                            : '#FF581A',
                'splice_site_variant, 3_prime_UTR_variant'       : '#FF581A',
                'splice_site_variant;splice_site_variant'        : '#FF581A',
                'stop_gained'                                    : '#ff0000',
                'stop_gained;stop_gained'                        : '#ff0000',
                'synonymous_variant'                             : '#76eeD0',
                'translocation'                                  : '#458b00',
                'trinucleotide_repeat_microsatellite_feature'    : '#7f7f7f',
                'trinucleotide_repeat_microsatellite_feature, 5_prime_UTR_variant' : '#7f7f7f',
                'Complex'                  : '#669900',
                'Deletion'                 : '#606080',
                'Duplication'              : '#406000',
                'Duplication (mosaic)'     : '#406000',
                'Homozygous deletion'      : '#606080',
                'Homozygous duplication'   : '#406000',
                'Mosaic deletion'          : '#606080',
                'N/A'                      : '#000D1A',
                'NA'                       : '#000D1A',
                'Triplication'             : '#406000',
                'Unknown'                  : '#000D1A',
                'complex'                  : '#669900'
            },
            constructor: function () {
                this.base.apply(this, arguments);

                if (this.legend === true) {
                    this.type = 'b';//this.id;

                    this.browser.addTrack(Genoverse.Track.Legend.extend({
                        id          : this.id   + 'Legend',
                        name        : this.name + ' Legend',
                        featureType : this.type
                    }), this.order + 0.1);
                }
            },
            insertFeature: function (feature) {
                feature.color  = this.prop('colorMap')[feature.variant_type];
                feature.legend = feature.variant_type;
                this.base(feature);
            }
        }),
        Genoverse.Track.extend({
            name            : 'AutDB: CNVs',
            id              : 'CNV',
            url             : '../Genoverse_Data/CNV_' + get_URL_coordParts('r', 'chr') + '.json', 
            //url : 'data/CNV_1.json',
            resizable       : 'auto',
            labels          : true,
            legend          : true,
            model           : Genoverse.Track.Model.extend(),
            view            : Genoverse.Track.View.Gene,
            colorMap        : {
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
                'Complex'                  : '#669900',
                'Deletion'                 : '#FF0000',
                'Duplication'              : '#0033CC',
                'Duplication (mosaic)'     : '#001F7D',
                'Homozygous deletion'      : '#800000',
                'Homozygous duplication'   : '#8080FF',
                'Mosaic deletion'          : '#330000',
                'N/A'                      : '#000D1A',
                'NA'                       : '#000D1A',
                'Triplication'             : '#003B00',
                'Unknown'                  : '#000D1A',
                'complex'                  : '#669900'
            },
            constructor: function () {
                this.base.apply(this, arguments);
                if (this.legend === true) {
                    this.type = this.id;
                    this.browser.addTrack(Genoverse.Track.Legend.extend({
                        id          : this.id   + 'Legend',
                        name        : this.name + ' Legend',
                        featureType : this.type
                    }), this.order + 0.2);
                }
            },
            insertFeature: function (feature) {
                feature.color  = this.prop('colorMap')[feature.variant_type];
                feature.legend = feature.variant_type;
                this.base(feature);
            }
        }),

        Genoverse.Track.dbSNP,
    ]
};
