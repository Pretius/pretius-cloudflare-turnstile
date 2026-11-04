------------------------------------------------------------------------------
-- Pretius Cloudflare Turnstile - Oracle APEX item plug-in
-- https://github.com/pretius/pretius-cloudflare-turnstile
-- MIT License
--
-- Readable copy of the plug-in PL/SQL code (Source > PL/SQL Code).
--
-- Component Settings (Scope: Application, once per app)
--   site_key_setting     Turnstile site key. Supports &ITEM. substitutions.
--   secret_key_setting   Turnstile secret key. Supports &ITEM. substitutions.
--                        Only ever used on the server.
--   enabled_setting      Y/N. N hides the widget and skips verification.
--
-- Item attributes (Scope: Component, per page item)
--   theme                auto | light | dark
--   size                 flexible | normal | compact
--   appearance           always | execute | interaction-only
--   action               optional widget action, verified on the server
--   error_message        shown when the check is missing or fails
--
-- The JavaScript lives in the plug-in file pretiusCloudflareTurnstile.js and
-- is loaded through the plug-in "File URLs to Load" attribute.
------------------------------------------------------------------------------

c_siteverify_url  constant varchar2(100) := 'https://challenges.cloudflare.com/turnstile/v0/siteverify';
c_default_error   constant varchar2(100) := 'Please complete the security check.';
c_timeout_seconds constant pls_integer   := 10;

-- Application-scope attribute with substitutions (&APP_ITEM.) resolved, so
-- keys can be kept outside the application definition.
function get_setting (
    p_plugin    in apex_plugin.t_plugin,
    p_static_id in varchar2 )
    return varchar2
is
begin
    return trim( apex_plugin_util.replace_substitutions(
                     p_value  => p_plugin.attributes.get_varchar2( p_static_id ),
                     p_escape => false ) );
end get_setting;

function is_enabled ( p_plugin in apex_plugin.t_plugin ) return boolean
is
begin
    return nvl( upper( get_setting( p_plugin, 'enabled_setting' ) ), 'Y' ) = 'Y';
end is_enabled;

-- Hidden input that holds the token, so it is submitted like any page item.
procedure render_hidden_input ( p_item in apex_plugin.t_item )
is
begin
    sys.htp.p(
        '<input type="hidden"'
     || ' id="'   || apex_escape.html_attribute( p_item.name ) || '"'
     || ' name="' || apex_escape.html_attribute( p_item.name ) || '"'
     || ' value="">' );
end render_hidden_input;

procedure render (
    p_item   in            apex_plugin.t_item,
    p_plugin in            apex_plugin.t_plugin,
    p_param  in            apex_plugin.t_item_render_param,
    p_result in out nocopy apex_plugin.t_item_render_result )
is
    l_container varchar2(255) := p_item.name || '_TURNSTILE';
    l_site_key  varchar2(4000);
begin
    if apex_application.g_debug then
        apex_plugin_util.debug_page_item(
            p_plugin    => p_plugin,
            p_page_item => p_item );
    end if;

    render_hidden_input( p_item );
    p_result.is_navigable := false;

    if not is_enabled( p_plugin ) then
        apex_debug.info( 'Turnstile: disabled in Component Settings, widget not rendered for %s', p_item.name );
        return;
    end if;

    if p_param.is_readonly or p_param.is_printer_friendly then
        return;
    end if;

    l_site_key := get_setting( p_plugin, 'site_key_setting' );

    if l_site_key is null then
        raise_application_error( -20001,
            'Turnstile: the Site Key component setting is empty (Shared Components > Component Settings > Pretius Cloudflare Turnstile).' );
    end if;

    sys.htp.p(
        '<div id="' || apex_escape.html_attribute( l_container ) || '"'
     || ' class="pretius-turnstile"></div>' );

    apex_javascript.add_onload_code(
        p_code => 'pretiusCloudflareTurnstile.init({'
               ||   'item:'         || apex_escape.js_literal( p_item.name )
               || ',container:'     || apex_escape.js_literal( l_container )
               || ',siteKey:'       || apex_escape.js_literal( l_site_key )
               || ',theme:'         || apex_escape.js_literal( nvl( p_item.attributes.get_varchar2( 'theme' ), 'auto' ) )
               || ',size:'          || apex_escape.js_literal( nvl( p_item.attributes.get_varchar2( 'size' ), 'flexible' ) )
               || ',appearance:'    || apex_escape.js_literal( nvl( p_item.attributes.get_varchar2( 'appearance' ), 'always' ) )
               || ',action:'        || apex_escape.js_literal( p_item.attributes.get_varchar2( 'action' ) )
               || ',errorMessage:'  || apex_escape.js_literal( nvl( p_item.attributes.get_varchar2( 'error_message' ), c_default_error ) )
               || '});' );
end render;

procedure validate (
    p_item   in            apex_plugin.t_item,
    p_plugin in            apex_plugin.t_plugin,
    p_param  in            apex_plugin.t_item_validation_param,
    p_result in out nocopy apex_plugin.t_item_validation_result )
is
    l_error      varchar2(4000) := nvl( p_item.attributes.get_varchar2( 'error_message' ), c_default_error );
    l_action     varchar2(255)  := p_item.attributes.get_varchar2( 'action' );
    l_secret_key varchar2(4000);
    l_names      apex_application_global.vc_arr2;
    l_values     apex_application_global.vc_arr2;
    l_response   clob;
begin
    if not is_enabled( p_plugin ) then
        return;
    end if;

    l_secret_key := get_setting( p_plugin, 'secret_key_setting' );

    if l_secret_key is null then
        raise_application_error( -20002,
            'Turnstile: the Secret Key component setting is empty (Shared Components > Component Settings > Pretius Cloudflare Turnstile).' );
    end if;

    if p_param.value is null then
        apex_debug.warn( 'Turnstile: no token was submitted for %s', p_item.name );
        p_result.message := l_error;
        return;
    end if;

    -- siteverify expects a form-encoded body
    l_names(1) := 'secret';   l_values(1) := l_secret_key;
    l_names(2) := 'response'; l_values(2) := p_param.value;

    apex_web_service.set_request_headers(
        p_name_01  => 'Content-Type',
        p_value_01 => 'application/x-www-form-urlencoded',
        p_reset    => true );

    begin
        l_response := apex_web_service.make_rest_request(
            p_url              => c_siteverify_url,
            p_http_method      => 'POST',
            p_parm_name        => l_names,
            p_parm_value       => l_values,
            p_transfer_timeout => c_timeout_seconds );
    exception
        when others then
            -- Fail closed: a network, ACL or wallet problem must not let the
            -- request through. Details go to the debug log only.
            apex_debug.error( 'Turnstile: siteverify call failed for %s: %s',
                              p_item.name, sqlerrm );
            p_result.message := l_error;
            return;
    end;

    if apex_web_service.g_status_code <> 200
       or nvl( json_value( l_response, '$.success' ), 'false' ) <> 'true'
    then
        apex_debug.warn( 'Turnstile: check failed for %s (HTTP %s): %s',
                         p_item.name,
                         apex_web_service.g_status_code,
                         substr( l_response, 1, 2000 ) );
        p_result.message := l_error;
        return;
    end if;

    if l_action is not null
       and nvl( json_value( l_response, '$.action' ), '#' ) <> l_action
    then
        apex_debug.warn( 'Turnstile: action mismatch for %s, expected %s, got %s',
                         p_item.name, l_action, json_value( l_response, '$.action' ) );
        p_result.message := l_error;
        return;
    end if;

    apex_debug.info( 'Turnstile: check passed for %s (hostname %s)',
                     p_item.name, json_value( l_response, '$.hostname' ) );
end validate;
