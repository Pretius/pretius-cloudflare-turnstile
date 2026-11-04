prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.6'
,p_default_workspace_id=>25304802788837055
,p_default_application_id=>116
,p_default_id_offset=>0
,p_default_owner=>'WKSP_LUF'
);
end;
/
 
prompt APPLICATION 116 - info
--
-- Application Export:
--   Application:     116
--   Name:            info
--   Date and Time:   17:08 Tuesday November 3, 2026
--   Exported By:     ADMIN
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 46704421364875888
--   Manifest End
--   Version:         26.1.6
--   Instance ID:     7700983794120159
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/item_type/com_pretius_apex_turnstile
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(46704421364875888)
,p_plugin_type=>'ITEM TYPE'
,p_name=>'COM.PRETIUS.APEX.TURNSTILE'
,p_display_name=>'Pretius Cloudflare Turnstile'
,p_apexlang_name=>'pretiusCloudflareTurnstile'
,p_supported_component_types=>'APEX_APPLICATION_PAGE_ITEMS'
,p_javascript_file_urls=>'#PLUGIN_FILES#pretiusCloudflareTurnstile.js'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'------------------------------------------------------------------------------',
'-- Pretius Cloudflare Turnstile - Oracle APEX item plug-in',
'-- https://github.com/pretius/pretius-cloudflare-turnstile',
'-- MIT License',
'--',
'-- Source of truth for the plug-in PL/SQL code. tools/build-plugin.mjs copies',
'-- this file into the plug-in export (plugin/*.sql) and the APEXlang app.',
'--',
'-- Component Settings (Scope: Application, once per app)',
'--   site_key_setting     Turnstile site key. Supports &ITEM. substitutions.',
'--   secret_key_setting   Turnstile secret key. Supports &ITEM. substitutions.',
'--                        Only ever used on the server.',
'--   enabled_setting      Y/N. N hides the widget and skips verification.',
'--',
'-- Item attributes (Scope: Component, per page item)',
'--   theme                auto | light | dark',
'--   size                 flexible | normal | compact',
'--   appearance           always | execute | interaction-only',
'--   action               optional widget action, verified on the server',
'--   error_message        shown when the check is missing or fails',
'--',
'-- The JavaScript lives in the plug-in file pretiusCloudflareTurnstile.js and',
'-- is loaded through the plug-in "File URLs to Load" attribute.',
'------------------------------------------------------------------------------',
'',
'c_siteverify_url  constant varchar2(100) := ''https://challenges.cloudflare.com/turnstile/v0/siteverify'';',
'c_default_error   constant varchar2(100) := ''Please complete the security check.'';',
'c_timeout_seconds constant pls_integer   := 10;',
'',
'-- Application-scope attribute with substitutions (&APP_ITEM.) resolved, so',
'-- keys can be kept outside the application definition.',
'function get_setting (',
'    p_plugin    in apex_plugin.t_plugin,',
'    p_static_id in varchar2 )',
'    return varchar2',
'is',
'begin',
'    return trim( apex_plugin_util.replace_substitutions(',
'                     p_value  => p_plugin.attributes.get_varchar2( p_static_id ),',
'                     p_escape => false ) );',
'end get_setting;',
'',
'function is_enabled ( p_plugin in apex_plugin.t_plugin ) return boolean',
'is',
'begin',
'    return nvl( upper( get_setting( p_plugin, ''enabled_setting'' ) ), ''Y'' ) = ''Y'';',
'end is_enabled;',
'',
'-- Hidden input that holds the token, so it is submitted like any page item.',
'procedure render_hidden_input ( p_item in apex_plugin.t_item )',
'is',
'begin',
'    sys.htp.p(',
'        ''<input type="hidden"''',
'     || '' id="''   || apex_escape.html_attribute( p_item.name ) || ''"''',
'     || '' name="'' || apex_escape.html_attribute( p_item.name ) || ''"''',
'     || '' value="">'' );',
'end render_hidden_input;',
'',
'procedure render (',
'    p_item   in            apex_plugin.t_item,',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_param  in            apex_plugin.t_item_render_param,',
'    p_result in out nocopy apex_plugin.t_item_render_result )',
'is',
'    l_container varchar2(255) := p_item.name || ''_TURNSTILE'';',
'    l_site_key  varchar2(4000);',
'begin',
'    if apex_application.g_debug then',
'        apex_plugin_util.debug_page_item(',
'            p_plugin    => p_plugin,',
'            p_page_item => p_item );',
'    end if;',
'',
'    render_hidden_input( p_item );',
'    p_result.is_navigable := false;',
'',
'    if not is_enabled( p_plugin ) then',
'        apex_debug.info( ''Turnstile: disabled in Component Settings, widget not rendered for %s'', p_item.name );',
'        return;',
'    end if;',
'',
'    if p_param.is_readonly or p_param.is_printer_friendly then',
'        return;',
'    end if;',
'',
'    l_site_key := get_setting( p_plugin, ''site_key_setting'' );',
'',
'    if l_site_key is null then',
'        raise_application_error( -20001,',
'            ''Turnstile: the Site Key component setting is empty (Shared Components > Component Settings > Pretius Cloudflare Turnstile).'' );',
'    end if;',
'',
'    sys.htp.p(',
'        ''<div id="'' || apex_escape.html_attribute( l_container ) || ''"''',
'     || '' class="pretius-turnstile"></div>'' );',
'',
'    apex_javascript.add_onload_code(',
'        p_code => ''pretiusCloudflareTurnstile.init({''',
'               ||   ''item:''         || apex_escape.js_literal( p_item.name )',
'               || '',container:''     || apex_escape.js_literal( l_container )',
'               || '',siteKey:''       || apex_escape.js_literal( l_site_key )',
'               || '',theme:''         || apex_escape.js_literal( nvl( p_item.attributes.get_varchar2( ''theme'' ), ''auto'' ) )',
'               || '',size:''          || apex_escape.js_literal( nvl( p_item.attributes.get_varchar2( ''size'' ), ''flexible'' ) )',
'               || '',appearance:''    || apex_escape.js_literal( nvl( p_item.attributes.get_varchar2( ''appearance'' ), ''always'' ) )',
'               || '',action:''        || apex_escape.js_literal( p_item.attributes.get_varchar2( ''action'' ) )',
'               || '',errorMessage:''  || apex_escape.js_literal( nvl( p_item.attributes.get_varchar2( ''error_message'' ), c_default_error ) )',
'               || ''});'' );',
'end render;',
'',
'procedure validate (',
'    p_item   in            apex_plugin.t_item,',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_param  in            apex_plugin.t_item_validation_param,',
'    p_result in out nocopy apex_plugin.t_item_validation_result )',
'is',
'    l_error      varchar2(4000) := nvl( p_item.attributes.get_varchar2( ''error_message'' ), c_default_error );',
'    l_action     varchar2(255)  := p_item.attributes.get_varchar2( ''action'' );',
'    l_secret_key varchar2(4000);',
'    l_names      apex_application_global.vc_arr2;',
'    l_values     apex_application_global.vc_arr2;',
'    l_response   clob;',
'begin',
'    if not is_enabled( p_plugin ) then',
'        return;',
'    end if;',
'',
'    l_secret_key := get_setting( p_plugin, ''secret_key_setting'' );',
'',
'    if l_secret_key is null then',
'        raise_application_error( -20002,',
'            ''Turnstile: the Secret Key component setting is empty (Shared Components > Component Settings > Pretius Cloudflare Turnstile).'' );',
'    end if;',
'',
'    if p_param.value is null then',
'        apex_debug.warn( ''Turnstile: no token was submitted for %s'', p_item.name );',
'        p_result.message := l_error;',
'        return;',
'    end if;',
'',
'    -- siteverify expects a form-encoded body',
'    l_names(1) := ''secret'';   l_values(1) := l_secret_key;',
'    l_names(2) := ''response''; l_values(2) := p_param.value;',
'',
'    apex_web_service.set_request_headers(',
'        p_name_01  => ''Content-Type'',',
'        p_value_01 => ''application/x-www-form-urlencoded'',',
'        p_reset    => true );',
'',
'    begin',
'        l_response := apex_web_service.make_rest_request(',
'            p_url              => c_siteverify_url,',
'            p_http_method      => ''POST'',',
'            p_parm_name        => l_names,',
'            p_parm_value       => l_values,',
'            p_transfer_timeout => c_timeout_seconds );',
'    exception',
'        when others then',
'            -- Fail closed: a network, ACL or wallet problem must not let the',
'            -- request through. Details go to the debug log only.',
'            apex_debug.error( ''Turnstile: siteverify call failed for %s: %s'',',
'                              p_item.name, sqlerrm );',
'            p_result.message := l_error;',
'            return;',
'    end;',
'',
'    if apex_web_service.g_status_code <> 200',
'       or nvl( json_value( l_response, ''$.success'' ), ''false'' ) <> ''true''',
'    then',
'        apex_debug.warn( ''Turnstile: check failed for %s (HTTP %s): %s'',',
'                         p_item.name,',
'                         apex_web_service.g_status_code,',
'                         substr( l_response, 1, 2000 ) );',
'        p_result.message := l_error;',
'        return;',
'    end if;',
'',
'    if l_action is not null',
'       and nvl( json_value( l_response, ''$.action'' ), ''#'' ) <> l_action',
'    then',
'        apex_debug.warn( ''Turnstile: action mismatch for %s, expected %s, got %s'',',
'                         p_item.name, l_action, json_value( l_response, ''$.action'' ) );',
'        p_result.message := l_error;',
'        return;',
'    end if;',
'',
'    apex_debug.info( ''Turnstile: check passed for %s (hostname %s)'',',
'                     p_item.name, json_value( l_response, ''$.hostname'' ) );',
'end validate;'))
,p_api_version=>3
,p_render_function=>'render'
,p_validation_function=>'validate'
,p_item_session_state_data_type=>'VARCHAR2'
,p_standard_attributes=>'VISIBLE:FORM_ELEMENT:SESSION_STATE'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Adds a Cloudflare Turnstile challenge to a page and verifies the token on the server when the page is submitted. If the token is missing, expired or rejected by Cloudflare, the item raises a validation error and page processing stops.</p>',
'<p><strong>Setup</strong></p>',
'<ol>',
'<li>Create a Turnstile widget in the Cloudflare dashboard and add the host name of your APEX instance.</li>',
'<li>Enter the site key and secret key in <em>Shared Components &gt; Component Settings &gt; Pretius Cloudflare Turnstile</em>.</li>',
'<li>Add a page item of type <em>Pretius Cloudflare Turnstile</em> to the form you want to protect.</li>',
'</ol>',
'<p>The database must be allowed to call <code>https://challenges.cloudflare.com</code> (network ACL for the APEX schema and a wallet that trusts its certificate). If the browser uses a Content Security Policy, allow <code>https://challenges.cloudflar'
||'e.com</code> in <code>script-src</code> and <code>frame-src</code>.</p>',
'<p>Only protect submits that execute validations. A button with <em>Execute Validations</em> set to No skips the check.</p>'))
,p_version_identifier=>'26.1.0'
,p_about_url=>'https://github.com/pretius/pretius-cloudflare-turnstile'
,p_files_version=>2461348170656
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(57306614329728108)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>40
,p_static_id=>'action'
,p_prompt=>'Action'
,p_apexlang_name=>'action'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_display_length=>32
,p_max_length=>32
,p_is_translatable=>false
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<code>login</code><br>',
'<code>contact-form</code>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Optional label that identifies this widget in Cloudflare analytics. Up to 32 characters: letters, numbers, hyphen and underscore.</p>',
'<p>When set, the server also checks that the token was issued for this action, so a token solved on another form cannot be replayed here.</p>'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(57306267695728108)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>30
,p_static_id=>'appearance'
,p_prompt=>'Appearance'
,p_apexlang_name=>'appearance'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'always'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>When the widget is visible on the page.</p>',
'<ul>',
'<li><strong>Always</strong> - shown all the time.</li>',
'<li><strong>Execute</strong> - shown only while the challenge is running.</li>',
'<li><strong>Interaction Only</strong> - shown only if the visitor has to interact with it.</li>',
'</ul>',
'<p>The widget mode (Managed, Non-interactive or Invisible) is set on the site key in the Cloudflare dashboard.</p>'))
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(57306323320728108)
,p_plugin_attribute_id=>wwv_flow_imp.id(57306267695728108)
,p_display_sequence=>10
,p_display_value=>'Always'
,p_return_value=>'always'
,p_apexlang_name=>'always'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(57306410624728108)
,p_plugin_attribute_id=>wwv_flow_imp.id(57306267695728108)
,p_display_sequence=>20
,p_display_value=>'Execute'
,p_return_value=>'execute'
,p_apexlang_name=>'execute'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(57306542463728108)
,p_plugin_attribute_id=>wwv_flow_imp.id(57306267695728108)
,p_display_sequence=>30
,p_display_value=>'Interaction Only'
,p_return_value=>'interaction-only'
,p_apexlang_name=>'interactionOnly'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(47704590040897459)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_attribute_scope=>'APPLICATION'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'enabled_setting'
,p_prompt=>'Enabled'
,p_apexlang_name=>'enabledSetting'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Turns Turnstile on or off for the whole application. When off, the widget is not rendered and submitted pages are not verified.</p>',
'<p>Only turn this off for local development: it removes the bot protection from every Turnstile item. For automated tests, prefer the Cloudflare dummy test keys.</p>'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(49104566856918590)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>50
,p_static_id=>'error_message'
,p_prompt=>'Error Message'
,p_apexlang_name=>'errorMessage'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_default_value=>'Please complete the security check.'
,p_display_length=>60
,p_is_translatable=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Message shown when the security check was not completed, has expired, or was rejected by Cloudflare.</p>',
'<p>The same message is used for the client-side check when the page is submitted with validation.</p>'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(47504587329894956)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_attribute_scope=>'APPLICATION'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'secret_key_setting'
,p_prompt=>'Secret Key'
,p_apexlang_name=>'secretKeySetting'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_display_length=>40
,p_is_translatable=>false
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<code>0x4AAAAAAAxxxxxxxxxxxxxxxxxxxxxxxxx</code><br>',
'<code>&amp;TURNSTILE_SECRET_KEY.</code>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>The Turnstile secret key. It is only used on the server to call the Cloudflare siteverify API and is never sent to the browser.</p>',
'<p>Component Settings are part of the application definition, so a key typed here is included in application exports. To keep it out of exports and source control, enter a substitution such as <code>&amp;TURNSTILE_SECRET_KEY.</code> and set that appl'
||'ication item from a secured table in an application process (On New Instance).</p>',
'<p>For testing, the Cloudflare dummy secret key <code>1x0000000000000000000000000000000AA</code> always passes.</p>'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(47304529804890676)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_attribute_scope=>'APPLICATION'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'site_key_setting'
,p_prompt=>'Site Key'
,p_apexlang_name=>'siteKeySetting'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_display_length=>40
,p_is_translatable=>false
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<code>0x4AAAAAAAxxxxxxxxxxxxxx</code><br>',
'<code>&amp;TURNSTILE_SITE_KEY.</code>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>The Turnstile site key from the Cloudflare dashboard. It is public and is sent to the browser.</p>',
'<p>Enter the key directly, or use a substitution such as <code>&amp;TURNSTILE_SITE_KEY.</code> so each environment can use its own key.</p>',
'<p>For testing, the Cloudflare dummy site key <code>1x00000000000000000000AA</code> always passes.</p>'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(48504514314908770)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'size'
,p_prompt=>'Size'
,p_apexlang_name=>'size'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'flexible'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>The widget size.</p>',
'<ul>',
'<li><strong>Flexible</strong> fills the width of its container (minimum 300px).</li>',
'<li><strong>Normal</strong> is 300 x 65px.</li>',
'<li><strong>Compact</strong> is 150 x 140px.</li>',
'</ul>'))
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(57306178578728107)
,p_plugin_attribute_id=>wwv_flow_imp.id(48504514314908770)
,p_display_sequence=>30
,p_display_value=>'Compact'
,p_return_value=>'compact'
,p_apexlang_name=>'compact'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(48704554678909928)
,p_plugin_attribute_id=>wwv_flow_imp.id(48504514314908770)
,p_display_sequence=>10
,p_display_value=>'Flexible'
,p_return_value=>'flexible'
,p_apexlang_name=>'flexible'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(57306001236728107)
,p_plugin_attribute_id=>wwv_flow_imp.id(48504514314908770)
,p_display_sequence=>20
,p_display_value=>'Normal'
,p_return_value=>'normal'
,p_apexlang_name=>'normal'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(47904511372901464)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'theme'
,p_prompt=>'Theme'
,p_apexlang_name=>'theme'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'auto'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'<p>The widget color theme. <strong>Auto</strong> follows the user''s browser or operating system preference.</p>'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(48104526149902751)
,p_plugin_attribute_id=>wwv_flow_imp.id(47904511372901464)
,p_display_sequence=>10
,p_display_value=>'Auto'
,p_return_value=>'auto'
,p_apexlang_name=>'auto'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(57305909684728107)
,p_plugin_attribute_id=>wwv_flow_imp.id(47904511372901464)
,p_display_sequence=>30
,p_display_value=>'Dark'
,p_return_value=>'dark'
,p_apexlang_name=>'dark'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(57305880748728107)
,p_plugin_attribute_id=>wwv_flow_imp.id(47904511372901464)
,p_display_sequence=>20
,p_display_value=>'Light'
,p_return_value=>'light'
,p_apexlang_name=>'light'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A210A202A205072657469757320436C6F7564666C617265205475726E7374696C65202D204F7261636C652041504558206974656D20706C75672D696E0A202A2068747470733A2F2F6769746875622E636F6D2F707265746975732F70726574697573';
wwv_flow_imp.g_varchar2_table(2) := '2D636C6F7564666C6172652D7475726E7374696C650A202A204D4954204C6963656E73650A202A2F0A2F2A20676C6F62616C2061706578202A2F0A77696E646F772E70726574697573436C6F7564666C6172655475726E7374696C65203D2077696E646F';
wwv_flow_imp.g_varchar2_table(3) := '772E70726574697573436C6F7564666C6172655475726E7374696C65207C7C202866756E6374696F6E2028242C206170657829207B0A202020202275736520737472696374223B0A0A202020207661722056455253494F4E203D202232362E312E30222C';
wwv_flow_imp.g_varchar2_table(4) := '0A20202020202020204C4F475F505245464958203D20225072657469757320436C6F7564666C617265205475726E7374696C653A222C0A20202020202020204F4E4C4F41445F43414C4C4241434B203D202270726574697573436C6F7564666C61726554';
wwv_flow_imp.g_varchar2_table(5) := '75726E7374696C654F6E6C6F6164222C0A20202020202020205343524950545F4944203D2022707265746975732D636C6F7564666C6172652D7475726E7374696C652D617069222C0A20202020202020205343524950545F55524C203D20226874747073';
wwv_flow_imp.g_varchar2_table(6) := '3A2F2F6368616C6C656E6765732E636C6F7564666C6172652E636F6D2F7475726E7374696C652F76302F6170692E6A733F72656E6465723D6578706C69636974266F6E6C6F61643D22202B204F4E4C4F41445F43414C4C4241434B2C0A20202020202020';
wwv_flow_imp.g_varchar2_table(7) := '207175657565203D205B5D2C0A202020202020202077696467657473203D207B7D2C202020202020202F2F206974656D206E616D65202D3E207B2077696467657449642C20636F6E666967207D0A20202020202020207363726970744661696C6564203D';
wwv_flow_imp.g_varchar2_table(8) := '2066616C73653B0A0A2020202066756E6374696F6E20697341706952656164792829207B0A202020202020202072657475726E2021212877696E646F772E7475726E7374696C652026262077696E646F772E7475726E7374696C652E72656E646572293B';
wwv_flow_imp.g_varchar2_table(9) := '0A202020207D0A0A2020202066756E6374696F6E20736574546F6B656E286974656D4E616D652C2076616C756529207B0A20202020202020202F2F20577269746520737472616967687420746F207468652068696464656E20696E7075743A2074686520';
wwv_flow_imp.g_varchar2_table(10) := '746F6B656E206973206E6F74207573657220646174612C20736F2069740A20202020202020202F2F206D757374206E6F74207261697365206368616E6765206576656E7473206F7220747269676765722022756E7361766564206368616E676573222077';
wwv_flow_imp.g_varchar2_table(11) := '61726E696E67732E0A20202020202020202428222322202B20242E65736361706553656C6563746F72286974656D4E616D6529292E76616C2876616C7565207C7C202222293B0A202020207D0A0A2020202066756E6374696F6E2063757272656E745265';
wwv_flow_imp.g_varchar2_table(12) := '73706F6E7365286974656D4E616D6529207B0A202020202020202076617220776964676574203D20776964676574735B6974656D4E616D655D3B0A20202020202020206966202821776964676574207C7C207769646765742E7769646765744964203D3D';
wwv_flow_imp.g_varchar2_table(13) := '3D20756E646566696E6564207C7C202169734170695265616479282929207B0A20202020202020202020202072657475726E2022223B0A20202020202020207D0A202020202020202072657475726E2077696E646F772E7475726E7374696C652E676574';
wwv_flow_imp.g_varchar2_table(14) := '526573706F6E7365287769646765742E776964676574496429207C7C2022223B0A202020207D0A0A2020202066756E6374696F6E2072656769737465724974656D2863666729207B0A2020202020202020617065782E6974656D2E637265617465286366';
wwv_flow_imp.g_varchar2_table(15) := '672E6974656D2C207B0A2020202020202020202020206974656D5F747970653A2022505245544955535F434C4F5544464C4152455F5455524E5354494C45222C0A20202020202020202020202069734368616E6765643A2066756E6374696F6E20282920';
wwv_flow_imp.g_varchar2_table(16) := '7B0A2020202020202020202020202020202072657475726E2066616C73653B0A2020202020202020202020207D2C0A2020202020202020202020202F2F2052657175697265643A206F6E636520616E206974656D20696E74657266616365206973206372';
wwv_flow_imp.g_varchar2_table(17) := '65617465642C20415045582070616765207375626D69740A2020202020202020202020202F2F207265616473207468652076616C7565207468726F7567682067657456616C75652C206E6F742066726F6D2074686520696E707574206469726563746C79';
wwv_flow_imp.g_varchar2_table(18) := '2E0A20202020202020202020202067657456616C75653A2066756E6374696F6E202829207B0A2020202020202020202020202020202072657475726E202428222322202B20242E65736361706553656C6563746F72286366672E6974656D29292E76616C';
wwv_flow_imp.g_varchar2_table(19) := '2829207C7C2022223B0A2020202020202020202020207D2C0A20202020202020202020202073657456616C75653A2066756E6374696F6E202876616C756529207B0A20202020202020202020202020202020736574546F6B656E286366672E6974656D2C';
wwv_flow_imp.g_varchar2_table(20) := '2076616C7565293B0A2020202020202020202020207D2C0A202020202020202020202020736574466F637573546F3A2066756E6374696F6E202829207B0A2020202020202020202020202020202072657475726E202428222322202B20242E6573636170';
wwv_flow_imp.g_varchar2_table(21) := '6553656C6563746F72286366672E636F6E7461696E657229293B0A2020202020202020202020207D2C0A2020202020202020202020202F2F20436C69656E742D7369646520636865636B207573656420627920617065782E706167652E76616C69646174';
wwv_flow_imp.g_varchar2_table(22) := '65207768656E206120627574746F6E0A2020202020202020202020202F2F207375626D69747320776974682076616C69646174696F6E2E205468652073657276657220616C7761797320766572696669657320616761696E2E0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(23) := '202067657456616C69646974793A2066756E6374696F6E202829207B0A202020202020202020202020202020207661722076616C6964203D2063757272656E74526573706F6E7365286366672E6974656D2920213D3D2022223B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(24) := '2020202020202072657475726E207B2076616C69643A2076616C69642C2076616C75654D697373696E673A202176616C6964207D3B0A2020202020202020202020207D2C0A20202020202020202020202067657456616C69646174696F6E4D6573736167';
wwv_flow_imp.g_varchar2_table(25) := '653A2066756E6374696F6E202829207B0A2020202020202020202020202020202072657475726E2063757272656E74526573706F6E7365286366672E6974656D2920213D3D202222203F202222203A206366672E6572726F724D6573736167653B0A2020';
wwv_flow_imp.g_varchar2_table(26) := '202020202020202020207D0A20202020202020207D293B0A202020207D0A0A2020202066756E6374696F6E2072656E6465722863666729207B0A2020202020202020766172206F7074696F6E73203D207B0A202020202020202020202020736974656B65';
wwv_flow_imp.g_varchar2_table(27) := '793A206366672E736974654B65792C0A2020202020202020202020207468656D653A206366672E7468656D652C0A20202020202020202020202073697A653A206366672E73697A652C0A202020202020202020202020617070656172616E63653A206366';
wwv_flow_imp.g_varchar2_table(28) := '672E617070656172616E63652C0A20202020202020202020202063616C6C6261636B3A2066756E6374696F6E2028746F6B656E29207B0A20202020202020202020202020202020736574546F6B656E286366672E6974656D2C20746F6B656E293B0A2020';
wwv_flow_imp.g_varchar2_table(29) := '202020202020202020207D2C0A20202020202020202020202022657870697265642D63616C6C6261636B223A2066756E6374696F6E202829207B0A20202020202020202020202020202020736574546F6B656E286366672E6974656D2C202222293B0A20';
wwv_flow_imp.g_varchar2_table(30) := '20202020202020202020207D2C0A2020202020202020202020202274696D656F75742D63616C6C6261636B223A2066756E6374696F6E202829207B0A20202020202020202020202020202020736574546F6B656E286366672E6974656D2C202222293B0A';
wwv_flow_imp.g_varchar2_table(31) := '2020202020202020202020207D2C0A202020202020202020202020226572726F722D63616C6C6261636B223A2066756E6374696F6E2028636F646529207B0A20202020202020202020202020202020736574546F6B656E286366672E6974656D2C202222';
wwv_flow_imp.g_varchar2_table(32) := '293B0A20202020202020202020202020202020617065782E64656275672E7761726E284C4F475F5052454649582C2022776964676574206572726F7220666F72222C206366672E6974656D2C20636F6465293B0A2020202020202020202020207D0A2020';
wwv_flow_imp.g_varchar2_table(33) := '2020202020207D3B0A0A2020202020202020696620286366672E616374696F6E29207B0A2020202020202020202020206F7074696F6E732E616374696F6E203D206366672E616374696F6E3B0A20202020202020207D0A0A202020202020202074727920';
wwv_flow_imp.g_varchar2_table(34) := '7B0A202020202020202020202020776964676574735B6366672E6974656D5D2E7769646765744964203D2077696E646F772E7475726E7374696C652E72656E64657228222322202B206366672E636F6E7461696E65722C206F7074696F6E73293B0A2020';
wwv_flow_imp.g_varchar2_table(35) := '2020202020207D20636174636820286529207B0A202020202020202020202020617065782E64656275672E6572726F72284C4F475F5052454649582C202272656E646572206661696C656420666F72222C206366672E6974656D2C2065293B0A20202020';
wwv_flow_imp.g_varchar2_table(36) := '202020207D0A202020207D0A0A2020202066756E6374696F6E206C6F61645363726970742829207B0A202020202020202069662028646F63756D656E742E676574456C656D656E7442794964285343524950545F49442929207B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(37) := '20202072657475726E3B0A20202020202020207D0A202020202020202076617220736372697074203D20646F63756D656E742E637265617465456C656D656E74282273637269707422293B0A20202020202020207363726970742E6964203D2053435249';
wwv_flow_imp.g_varchar2_table(38) := '50545F49443B0A20202020202020207363726970742E737263203D205343524950545F55524C3B0A20202020202020207363726970742E6173796E63203D20747275653B0A20202020202020207363726970742E6465666572203D20747275653B0A2020';
wwv_flow_imp.g_varchar2_table(39) := '2020202020207363726970742E6F6E6572726F72203D2066756E6374696F6E202829207B0A2020202020202020202020207363726970744661696C6564203D20747275653B0A202020202020202020202020617065782E64656275672E6572726F72284C';
wwv_flow_imp.g_varchar2_table(40) := '4F475F5052454649582C2022636F756C64206E6F74206C6F61642022202B205343524950545F55524C202B0A20202020202020202020202020202020222E20436865636B20746865206E6574776F726B20616E642074686520436F6E74656E7420536563';
wwv_flow_imp.g_varchar2_table(41) := '757269747920506F6C69637920287363726970742D73726320616E64206672616D652D7372632068747470733A2F2F6368616C6C656E6765732E636C6F7564666C6172652E636F6D292E22293B0A20202020202020207D3B0A2020202020202020646F63';
wwv_flow_imp.g_varchar2_table(42) := '756D656E742E686561642E617070656E644368696C6428736372697074293B0A202020207D0A0A2020202077696E646F775B4F4E4C4F41445F43414C4C4241434B5D203D2066756E6374696F6E202829207B0A202020202020202071756575652E73706C';
wwv_flow_imp.g_varchar2_table(43) := '6963652830292E666F72456163682872656E646572293B0A202020207D3B0A0A202020202F2F204561636820746F6B656E2063616E206F6E6C79206265207665726966696564206F6E63652E204F6E63652074686520706167652069732061637475616C';
wwv_flow_imp.g_varchar2_table(44) := '6C79206265696E670A202020202F2F207375626D69747465642028616674657220636C69656E742D736964652076616C69646174696F6E292C2073746172742061206672657368206368616C6C656E676520736F20610A202020202F2F206661696C6564';
wwv_flow_imp.g_varchar2_table(45) := '207365727665722D736964652076616C69646174696F6E2063616E2062652072657375626D69747465642E20546865207375626D697474656420746F6B656E2069730A202020202F2F206C65667420696E20746865206974656D3A206974206973207265';
wwv_flow_imp.g_varchar2_table(46) := '706C61636564207768656E20746865206E6577206368616C6C656E676520636F6D706C657465732E0A202020202428646F63756D656E74292E6F6E282261706578706167657375626D6974222C2066756E6374696F6E202829207B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(47) := '73657454696D656F75742866756E6374696F6E202829207B0A2020202020202020202020204F626A6563742E6B6579732877696467657473292E666F72456163682866756E6374696F6E20286974656D4E616D6529207B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(48) := '202020207265736574286974656D4E616D652C2074727565293B0A2020202020202020202020207D293B0A20202020202020207D2C2030293B0A202020207D293B0A0A2020202066756E6374696F6E207265736574286974656D4E616D652C206B656570';
wwv_flow_imp.g_varchar2_table(49) := '56616C756529207B0A202020202020202076617220776964676574203D20776964676574735B6974656D4E616D655D3B0A20202020202020206966202821776964676574207C7C207769646765742E7769646765744964203D3D3D20756E646566696E65';
wwv_flow_imp.g_varchar2_table(50) := '64207C7C202169734170695265616479282929207B0A20202020202020202020202072657475726E3B0A20202020202020207D0A202020202020202069662028216B65657056616C756529207B0A202020202020202020202020736574546F6B656E2869';
wwv_flow_imp.g_varchar2_table(51) := '74656D4E616D652C202222293B0A20202020202020207D0A202020202020202077696E646F772E7475726E7374696C652E7265736574287769646765742E7769646765744964293B0A202020207D0A0A2020202072657475726E207B0A20202020202020';
wwv_flow_imp.g_varchar2_table(52) := '202F2A2A0A2020202020202020202A2043616C6C65642062792074686520706C75672D696E2072656E6465722070726F63656475726520666F72206576657279205475726E7374696C65206974656D2E0A2020202020202020202A2040706172616D207B';
wwv_flow_imp.g_varchar2_table(53) := '4F626A6563747D20636667206974656D2C20636F6E7461696E65722C20736974654B65792C207468656D652C2073697A652C20617070656172616E63652C20616374696F6E2C206572726F724D6573736167650A2020202020202020202A2F0A20202020';
wwv_flow_imp.g_varchar2_table(54) := '20202020696E69743A2066756E6374696F6E202863666729207B0A20202020202020202020202069662028776964676574735B6366672E6974656D5D29207B0A2020202020202020202020202020202072657475726E3B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(55) := '7D0A202020202020202020202020776964676574735B6366672E6974656D5D203D207B20636F6E6669673A20636667207D3B0A20202020202020202020202072656769737465724974656D28636667293B0A0A2020202020202020202020206966202869';
wwv_flow_imp.g_varchar2_table(56) := '734170695265616479282929207B0A2020202020202020202020202020202072656E64657228636667293B0A2020202020202020202020202020202072657475726E3B0A2020202020202020202020207D0A20202020202020202020202071756575652E';
wwv_flow_imp.g_varchar2_table(57) := '7075736828636667293B0A2020202020202020202020206C6F616453637269707428293B0A20202020202020207D2C0A0A20202020202020202F2A2A20436C656172732074686520746F6B656E20616E64207374617274732061206E6577206368616C6C';
wwv_flow_imp.g_varchar2_table(58) := '656E676520666F7220746865206974656D2E202A2F0A202020202020202072657365743A2066756E6374696F6E20286974656D4E616D6529207B0A2020202020202020202020207265736574286974656D4E616D652C2066616C7365293B0A2020202020';
wwv_flow_imp.g_varchar2_table(59) := '2020207D2C0A0A20202020202020202F2A2A2052657475726E73207468652063757272656E7420746F6B656E20666F7220746865206974656D2C206F72202222206966206E6F6E652E202A2F0A2020202020202020676574526573706F6E73653A206675';
wwv_flow_imp.g_varchar2_table(60) := '6E6374696F6E20286974656D4E616D6529207B0A20202020202020202020202072657475726E2063757272656E74526573706F6E7365286974656D4E616D65293B0A20202020202020207D2C0A0A20202020202020202F2A2A2054727565207768656E20';
wwv_flow_imp.g_varchar2_table(61) := '74686520436C6F7564666C6172652073637269707420636F756C64206E6F74206265206C6F616465642E202A2F0A20202020202020206861734C6F61644572726F723A2066756E6374696F6E202829207B0A20202020202020202020202072657475726E';
wwv_flow_imp.g_varchar2_table(62) := '207363726970744661696C65643B0A20202020202020207D2C0A0A202020202020202067657456657273696F6E3A2066756E6374696F6E202829207B0A20202020202020202020202072657475726E2056455253494F4E3B0A20202020202020207D0A20';
wwv_flow_imp.g_varchar2_table(63) := '2020207D3B0A7D2928617065782E6A51756572792C2061706578293B0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(57306765722728109)
,p_plugin_id=>wwv_flow_imp.id(46704421364875888)
,p_file_name=>'pretiusCloudflareTurnstile.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
