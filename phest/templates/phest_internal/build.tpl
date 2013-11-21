<!DOCTYPE html>
<html>
<head>
 <title>Phest {$ver}</title>
 <link href="./assets/bootstrap/css/bootstrap.css" rel="stylesheet">
<!--[if lt IE 9]>
<script type="text/javascript" src="./assets/jquery-1.10.2.min.js"></script>
<![endif]-->
<!--[if gte IE 9]><!-->
<script type="text/javascript" src="./assets/jquery-2.0.3.min.js"></script>
<!--<![endif]-->
<script type="text/javascript" src="./assets/bootstrap/js/bootstrap.js"></script>
<script type="text/javascript" src="./assets/underscore-min.js"></script>
<script type="text/javascript" src="./assets/NotificationAPI.js"></script>
<script type="text/javascript" src="./assets/common.js"></script>
<style type="text/css">
section {
  padding:0px 10px;
  max-width:700px;
}

.toolBar {
	width: 700px;
	margin: 10px 10px;
}

.toolBar tbody tr {
	text-align: center;
}

a {
  cursor: pointer;
}

.newSite {
  font-size:12px;
}
</style>
<script type="text/javascript">
$(function(){
  var query = {};
  parse_str(window.location.search.substr(1),query);
  
  var build = '';
  if (query.build){
    build = query.build;
  }
  
  $('#site').change(function(){
    document.location.href = '?site=' + $(this).val();
  });
  
  $('#createSite').click(function(){
    var sitename = prompt("作成したいサイト名を入力してください",'');
    if (sitename){
      document.location.href = '?create_site=' + sitename;
    }
  });

  $('#buildLocal').click(function(){
    $('.btn').addClass('disabled');
    $('#result').fadeOut();
    document.location.href = create_query('local');
  });
  
  $('#buildProduction').click(function(){
    $('.btn').addClass('disabled');
    $('#result').fadeOut();
    document.location.href = create_query('production');
  });

  var watch_timer = null;
  $('#buildLocalWatch').click(function(){
    //デスクトップ通知
    if (NotificationAPI.checkPermission() != 0){
      NotificationAPI.requestPermission();
    }
    
    if (build != 'watch'){
      document.location.href = create_query('watch');
    }
    
    $('#result').fadeOut();
    
    var watching = false;
    if (watch_timer){
      $('#watchStatus').hide();
      
      clearInterval(watch_timer);
      watch_timer = null;
      $('#watchIcon').removeClass('glyphicon-stop').addClass('glyphicon-refresh');
      $('#watchText').text('Local watch');
      $('#buildLocal').removeClass('disabled');
      $('#buildProduction').removeClass('disabled');
    }else{
      $('#watchStatus').fadeIn();
      
      watch_timer = setInterval(function(){
        if (!watching){
          watching = true;
          $.getJSON(create_query('local',1),function(data){
            if (data){
              build_result(data.message_list);
              
              for (var i = 0,sec_len = data.message_list.length;i < sec_len;i++){
                var section = data.message_list[i];
                
                var body = '';
                switch (section.type){
                  case 'danger':
                    var body = section.list.length + ' errors';
                  case 'success':
                    (function(){
                      var popup = NotificationAPI.createNotification('./assets/image/' + section.type + '.png',strip_tags(section.title),body);
                      popup.onclick = function(){
                        window.focus();
                        this.cancel();
                      };
                      popup.show();
                      
                      setTimeout(function(){
                        popup.close();
                      },3000);
                    })();
                    break;
                  default:
                    break;
                }
              }
            }
          });
          watching = false;
        }
      },1000);

      $('#watchIcon').removeClass('glyphicon-refresh').addClass('glyphicon-stop');
      $('#watchText').text('pause');
      $('#buildLocal').addClass('disabled');
      $('#buildProduction').addClass('disabled');
    }
  });
  
  var message_list_tpl = _.template($('#messageListTemplate').html());
  
  var build_result = function(message_list){
    $('#result').html(message_list_tpl({
      message_list:message_list
    })).show();
  };
  
  var create_query = function(buildtype,watch){
    var str = '?build=' + buildtype;
    if (watch){
      str += '&watch=1';
    }
    var site = $('#site').val();
    if (site){
      str += '&site=' + site;
    }
    var lang = $('#lang').val();
    if (lang){
      str += '&lang=' + lang;
    }
    return str;
  };
  
  var message_list = {if isset($message_list)}{$message_list|json_encode}{else}null{/if};
  
  if (message_list){
    build_result(message_list);
  }
  
  if (build == 'watch'){
     $('#buildLocalWatch').click();
  }
});
</script>
</head>
<body>
<section class="toolBar">
<table class="table table-bordered">
 <thead>
  <tr style="text-align:center">
    <td>サイト</td>
   {if $lang}
    <td>言語</td>
   {/if}
    <td>ビルド実行</td>
  </tr>
 </thead>
 <tbody>
  <tr>
   <td>
    <select id="site" name="site" class="form-control">
     {foreach $site_list as $site_val}
      <option value="{$site_val}"{if $site_val == $site} selected{/if}>{$site_val}</option>
     {/foreach}
    </select>
    <a id="createSite" class="newSite">新しくサイトを作成</a>
   </td>
   {if $lang}
   <td>
    <select id="lang" name="lang" class="form-control">
     {foreach $lang_list as $lang_val}
      <option value="{$lang_val}"{if $lang_val == $lang} selected{/if}>{$lang_val}</option>
     {/foreach}
    </select>
   </td>
   {/if}
   <td>
    <button id="buildLocal" class="btn btn-primary">Local</button>
    <button id="buildLocalWatch" class="btn btn-primary"><span id="watchIcon" class="glyphicon glyphicon-refresh"></span> <span id="watchText">Local watch</span></button>
    <button id="buildProduction" class="btn btn-success"><span class="glyphicon glyphicon-ok"></span> Production</button>
   </td>
  </tr>
 </tbody>
</table>
</section>

<div id="watchStatus" style="padding:5px;display:none"><img src="./assets/image/ajax-loader.gif" style="width:25px;height:25px"/>更新をチェック中....</div>
<section id="result" class="resultSection"></section>

<script id="messageListTemplate" type="text/template">
 <% _.each(message_list,function(section_dat){ %>
  <div class="panel panel-<%= section_dat.type %>">
   <div class="panel-heading">
    <h3 class="panel-title"><%= section_dat.title %></h3>
   </div>
   <div class="panel-body">
    <ul>
     <% _.each(section_dat.list,function(msg){ %>
      <li><%= msg %></li>
     <% }); %>
    </ul>
   </div>
  </div>
 <% }); %>
</script>