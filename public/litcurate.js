var LitCurate = {
  style: 'apa',
  citeproc_sys: {
    retrieveLocale: function (lang){
      var xhr = new XMLHttpRequest();
      //xhr.open('GET', 'https://raw.githubusercontent.com/Juris-M/citeproc-js-docs/master/locales-' + lang + '.xml', false);
      xhr.open('GET', 'https://raw.githubusercontent.com/citation-style-language/locales/master/locales-' + lang + '.xml', false);
      xhr.send(null);
      return xhr.responseText;
    },
    retrieveItem: function(id){
      return $("#"+id).data().metadata;
    }
  },
  get_processor: function(styleID) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', 'https://raw.githubusercontent.com/citation-style-language/styles/master/' + styleID + '.csl', false);
    xhr.send(null);
    var styleAsText = xhr.responseText;
    var citeproc = new CSL.Engine(this.citeproc_sys, styleAsText);
    return citeproc;
  }
};
function format_citations(){
  var document_ids = [];
  $("#documents li").each(function(index, elem){
    document_ids.push(elem.id);
  });
  console.log("format_citetions: document_ids::", document_ids);
  var citeproc = LitCurate.get_processor(LitCurate.style);
  citeproc.updateItems(document_ids);
  var results = citeproc.makeBibliography();
  console.log("format_citations: results::", results);
  $.each(results[0].entry_ids, function(index, elem){
    console.log("#"+elem, results[1][index]);
    $("#"+elem).data("citation", results[1][index]);
    $("#"+elem).attr("title", results[1][index]);
    $("#"+elem).tooltip({
      html: true,
      placement: "auto top"
    });
  });
}

function reset_all(){
  $("#documents").empty();
  $("#axis").empty();
  $("#annotations").empty();
  $("#annotation-panel").hide();
}

function litcurate_alert(message){
  var elem = $(".litcurate-alert");
  elem.find("span").html(message);
  elem.fadeIn().delay(4000).fadeOut();
}

function error_report(data, statusText, errorThrown){
  console.log("error_report", data, statusText, errorThrown);
  str = statusText;
  if (errorThrown) str += ": " + errorThrown;
  litcurate_alert(str);
}

function prepare_draggable(elem){
  $(elem).draggable({
    revert: "invalid"
  });
}

function load_documents(folder){
  $("#documents").append('<span class="loading-documents"><i class="fa fa-spinner fa-spin fa-3x fa-fw"></i><span class="sr-only">Loading...</span></span>');
  $.ajax({
    url: "/load_documents",
    data: { folder: folder },
    success: function(data, status, params){
      var ajax_calls = [];
      $.each(data, function(index, val){
        console.log(val);
        ajax_calls.push($.ajax({
          url: "/load_document",
          data: { id: val["id"] },
          success: function(data, status, params){
            console.log(data);
            var author = data["authors"][0]["last_name"];
            var year = data["year"];
            $("#documents").append('<li id="'+data["id"]+'" class="btn btn-default btn-sm document">'+author+", "+year+"</li>");
            prepare_draggable("#"+data["id"]);
            // For CSL mapping:
            if (!data.author){ data.author = data.authors }
            $.each(data.author, function(i, e){
              if (!data.author[i].given) { data.author[i].given = data.author[i].first_name; }
              if (!data.author[i].family) { data.author[i].given = data.author[i].last_name; }
            });
            if (!data.issued){ data.issued = { raw: data.year } }
            if (!data.page){ data.page = data.pages }
            if (!data["container-title"]){ data["container-title"] = data.source }
            $("#"+data["id"]).data("metadata", data);
          }
        }));
      });
      $.when.apply($, ajax_calls).always(function(){
        $("span.loading-documents").fadeOut();
        format_citations();
      });
    },
    error: error_report
  });
}

function load_annotations(folder){
  $.ajax({
    url: "/load_annotations",
    data: { folder: folder },
    success: function(data, status, params){
      $("#axis").empty();
      console.log("load_annotations", data);
      $.each(data, function(index, val){
        $("#axis").append('<li id="annotation-'+val["id"]+'" class="annotation btn btn-default">'+val["name"]+"</li>");
      });
    }
  });
}

function annotation_form(data){
  console.log("annotation_form", data);
  var str = '';
  str += '<div class="row"><div class="col-md-12"><form class="form-horizontal">'+
   '<input type="hidden" name="id" id="id" value="'+data["id"]+'"/>'+
   '<input type="hidden" name="folder" id="folder" value="'+data["folder"]+'"/>'+
   '<div class="form-group">'+
   '<label class="col-md-4 control-label" for="name">Name</label>'+
   '<div class="col-md-6">'+
   '<input id="name" name="name" type="text" placeholder="Name" value="'+data["name"]+'" class="form-control input-md"/>'+
   '</div></div>'+
   '<div class="form-group"><label class="col-md-4 control-label" for="items">Items</label>'+
   '<div id="items" class="col-md-6">';
  var count = 1;
  $.each(data["items"], function(index, elem){
    str += '<input name="items" type="text" placeholder="Item '+count+'" value="'+elem+'" class="form-control input-md item"/>';
    count += 1;
  });
  str += '<input name="items" type="text" placeholder="Item '+count+'" class="form-control input-md item"/>';
  str += '</div>';
  str += '<p class="col-md-10 text-right"><a id="add_item_input">more items...</a></p>';
  str += '</div></form></div></div>';
  $("#items").data({count: count});
  return str;
}
function add_item_input(){
  var count = $("#items").data().count;
  if(!count) count = 2;
  console.log("add_item_input", count);
  var str = '<input name="items" type="text" placeholder="Item '+count+'" class="form-control input-md item"/>';
  $(str).appendTo("#items");
  $("#items").data({count: count+1});
}

function new_annotation(){
  var form_data = {};
  form_data["folder"] = $("#folders option:selected").val();
  bootbox.dialog({
    title: "New annotation",
    message: annotation_form(form_data),
    onEscape: true,
    backdrop: true,
    buttons: {
      success: {
        label: "Save",
        className: "btn-success",
        callback: function(){
          var name = $("#name").val();
          var folder = $("#folder").val();
          var items = [];
          $("#items .item").each(function(i, e){
            var item = $(this).val();
            if (item) {
              items.push(item);
            }
          });
          console.log("new_annotation", name, folder, items);
          $.ajax({
            url: "/new_annotation",
            data: { name: name, folder: folder, item: items },
            method: "POST",
            success: function(){
              load_annotations(folder);
            }
          });
        }
      }
    }
  });
}
function edit_annotation(annotation_id){
  var items = [];
  $(".item-cell").each(function(index){
    items.push($(this).data("name"));
  });
  var form_data = {
    id: annotation_id,
    folder: $("#folders option:selected").val(),
    name: $("#annotations").data("name"),
    items: items
  };
  bootbox.dialog({
    title: "Edit annotation",
    message: annotation_form(form_data),
    onEscape: true,
    backdrop: true,
    buttons: {
      success: {
        label: "Save",
        className: "btn-success",
        callback: function(){
          var name = $("#name").val();
          var folder = $("#folder").val();
          var items = [];
          $("#items .item").each(function(i, e){
            var item = $(this).val();
            if (item) {
              items.push(item);
            }
          });
          console.log("edit_annotation", annotation_id, name, folder, items);
          $.ajax({
            url: "/save_annotation",
            data: { id: annotation_id, name: name, folder: folder, item: items },
            method: "POST",
            success: function(){
              unload_annotation();
              load_annotations(folder);
            }
          });
        }
      }
    }
  });
}

function update_document(document_id, annotation_name, item_name) {
  console.log("update_document", document_id, annotation_name, item_name);
  var tags = [];
  $.each($("#"+document_id).data("metadata").tags, function(i, e){
    if (!e.startsWith(annotation_name+"-")) {
      tags.push(e);
    }
  });
  tags.push(annotation_name+"-"+item_name);
  console.log(tags);
  $.ajax({
    url: "/update_document",
    data: { id: document_id, tags: tags },
    method: "POST",
    success: function(data, status, params){
      $.ajax({
        url: "/load_document",
        data: { id: document_id },
        success: function(data, status, params){
          console.log("update_document", data);
          $("#"+data["id"]).data("metadata", data);
        }
      });
    },
    error: error_report
  });
}

function load_annotation(annotation){
  $("#axis .annotation.btn-primary").removeClass("btn-primary");
  $("#annotations li").each(function(){
    $("#documents").append(this);
  });
  $(annotation).addClass("btn-primary");
  $("#annotation-panel").show();
  var annotation_id = annotation.id.replace(/^annotation-/, "");
  var annotation_name = $(annotation).text();
  $("#annotations").data("name", annotation_name);
  $.ajax({
    url: "/load_items",
    data: { annotation: annotation_id },
    success: function(data){
      //console.log(data);
      $("#annotations").empty();
      var row = $("<tr/>");
      var row_cell = $("<tr/>");
      var width = 100 / data.length;
      $.each(data, function(index, val){
        row.append('<th style="width:'+width+'%">'+val.name+'</th>');
        row_cell.append('<td class="item"><ul class="list-unstyled item-cell"></ul></td>');
      });
      $("#annotations").append(row);
      $("#annotations").append(row_cell);
      $(".item-cell").each(function(index){
        $(this).data("name", data[index].name);
      });
      $("#documents li.document").each(function(index, elem){
        console.log($(elem).data("metadata").tags);
        $.each($(elem).data("metadata").tags, function(index, val){
          $(".item-cell").each(function(index_item, item_elem){
            var item_name = annotation_name + "-" + data[index_item].name;
            if (val == item_name) {
              $(elem).appendTo(this);
            }
          });
        });
      });
      $(".item-cell").droppable({
        accept: "#documents .document, #annotations .item-cell .document",
        drop: function(event, ui){
          $(ui.draggable).css({
            position: "static",
            left: 0,
            top: 0
          }).appendTo(this);
          prepare_draggable(ui.draggable);
          update_document($(ui.draggable).data("metadata").id, $("#annotations").data("name"), $(this).data("name"));
          //console.log($(ui.draggable).data("metadata"));
          //console.log($(ui.draggable).data("metadata").id);
          //console.log($(this).data("name"));
          //console.log($("#annotations").data("name"));
        }
      });
      $("#annotation-panel").show();
    }
  });
}

function unload_annotation(annotation){
  $(annotation).removeClass("btn-primary");
  $(".item li").appendTo("#documents");
  $("#annotations").empty();
  $("#annotation-panel").hide();
}

function reload_folders(){
  reset_all();
  $("#folders option").each(function(){
    if ($(this).val()) {
      //console.log($(this).val());
      $(this).remove();
    }
  });
  $.get("/load_folders", function(data){
    console.log("load_folders", data);
    $.each(data, function(index, folder){
      $("#folders").append('<option value="'+folder.id+'">'+folder.name+'</option');
    });
  });
}

function delete_annotation(annotation_id){
  console.log("delete_annotation", annotation_id);
  $.post("/delete_annotation", { annotation: annotation_id }, function(data, status, xhr){
    unload_annotation();
    load_annotations($("#folders option:selected").val());
  });
}

$(function(){
  $("#folders").change(function(e){
    var elem = $("#folders option:selected");
    var id = elem.val();
    var label = elem.text();
    if (!id) {
      $(".new-annotation").hide();
    } else {
      reset_all();
      load_documents(id);
      load_annotations(id);
      $(".new-annotation").show();
    }
  });
  $("#refresh-folders").click(function(e){
    reload_folders();
  });
  $("#new_annotation").click(function(e){
    e.preventDefault();
    new_annotation();
  });
  $(document).on("click", "#add_item_input", function(e){
    e.preventDefault();
    add_item_input();
  });
  $("#annotation-delete").click(function(e){
    var annotation_id = $("#axis li.btn-primary").attr("id").replace(/^annotation-/, "");
    delete_annotation(annotation_id);
  });
  $("#annotation-edit").click(function(e){
    var annotation_id = $("#axis li.btn-primary").attr("id").replace(/^annotation-/, "");
    edit_annotation(annotation_id);
  });
  $("#axis").on("click", ".annotation", function(e){
    if ($(e.target).hasClass("btn-primary")) {
      unload_annotation(e.target);
    } else {
      load_annotation(e.target);
    }
  });
});
