<#include "/template/java/canon-template-java-Prologue.ftl">
<@setPrologueJavaType model/>
import java.io.IOException;
import java.io.StringReader;

import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.concurrent.ExecutorService;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.annotation.concurrent.Immutable;

import javax.servlet.AsyncContext;
import javax.servlet.ServletInputStream;
import javax.servlet.ServletOutputStream;

import com.symphony.oss.commons.dom.json.ImmutableJsonObject;
import com.symphony.oss.commons.dom.json.JsonValue;

import com.symphony.oss.canon.runtime.AsyncPathHandler;
import com.symphony.oss.canon.runtime.EmptyRequestManager;
import com.symphony.oss.canon.runtime.PayloadOnlyRequestManager;
import com.symphony.oss.canon.runtime.PayloadResponseRequestManager;
import com.symphony.oss.canon.runtime.ResponseOnlyRequestManager;
import com.symphony.oss.canon.runtime.ModelRegistry;
import com.symphony.oss.canon.runtime.exception.BadRequestException;
import com.symphony.oss.canon.runtime.exception.CanonException;
import com.symphony.oss.canon.runtime.exception.NotFoundException;
import com.symphony.oss.canon.runtime.exception.PermissionDeniedException;
import com.symphony.oss.canon.runtime.exception.ServerErrorException;
import com.symphony.oss.canon.runtime.http.IRequestAuthenticator;
import com.symphony.oss.canon.runtime.http.ParameterLocation;
import com.symphony.oss.canon.runtime.http.IAsyncRequestContext;
import com.symphony.oss.fugue.pipeline.IConsumer;

<@importFieldTypes model true/>
<@importFacadePackages model/>

<#include "/template/java/Path/Path.ftl">
@Immutable
@SuppressWarnings("unused")
public abstract class ${modelJavaClassName}AsyncPathHandler<A> extends AsyncPathHandler<A> implements I${modelJavaClassName}AsyncPathHandler<A>
{
  public ${modelJavaClassName}AsyncPathHandler(
    ExecutorService processExecutor,
    ExecutorService responseExecutor,
    @Nullable IRequestAuthenticator<A> authenticator)
  {
    super(processExecutor, responseExecutor, authenticator, ${model.pathParamCnt}, new String[] {
<#list model.partList as part>
        "${part}"<#sep>,
</#list>
      }
    );
  }

  @Override
  public String getPath()
  {
    return "${model.absolutePath}";
  }

  @Override
  public void handle(A auth, IAsyncRequestContext context, List<String> pathParams) throws IOException, CanonException
  {
    switch(context.getMethod())
    {
<#if model.unsupportedOperations?size != 0>
  <#list model.unsupportedOperations as operation>
      case ${operation}:
  </#list>
        unsupportedMethod(auth, context);
        break;
        
</#if>
<#list model.operations as operation>
  <@setJavaMethod operation/>
      case ${operation.camelCapitalizedName}:
        do${operation.camelCapitalizedName}(auth, context, pathParams);
        break;
        
</#list>
    }
  }
<#list model.operations as operation>
  
  <@setJavaMethod operation/>
  
  private void do${operation.camelCapitalizedName}(A auth, IAsyncRequestContext context, List<String> pathParams) throws IOException, CanonException
  {
  <#include "/template/java/Path/GetParams.ftl">

  
    if(context.preConditionsAreMet())
    {
      ServletInputStream in = context.getInputStream();
      ServletOutputStream out = context.getOutputStream();
      AsyncContext async=context.startAsync();

      <#list operation.parameters as parameter>
        <@setJavaType parameter.schema/>
        final ${javaClassName?right_pad(25)} final${parameter.camelCapitalizedName} = ${parameter.camelName}; 
      </#list>
      
  <#switch methodStyle>
    <#case "PayloadResponse">
      // Method has both Payload and Response
      PayloadResponseRequestManager<A,${methodPayloadElementType}, ${methodResponseElementType}> manager =
        new PayloadResponseRequestManager<A,${methodPayloadElementType}, ${methodResponseElementType}>(in, out, auth, context.getTrace(), async, getProcessExecutor(), getResponseExecutor())
      {
        @Override
        public void handle(@Nonnull ${methodPayloadElementType} payload, IConsumer<${methodResponseElementType}> consumer) throws CanonException
        {
          handle${operation.camelCapitalizedName}(payload, consumer, getAuth(), getTrace()<#if operation.parameters?size != 0>,</#if>
      <#list operation.parameters as parameter>
        final${parameter.camelCapitalizedName}<#sep>,</#sep>
      </#list>
          );
        }
      <@setJavaType operation.payload.schema/>
  
        @Override
        protected ${methodPayloadElementType} parsePayload(String request)
        {
      <#if operation.payload.schema.isTypeDef>
          JsonValue<?, ?> jsonValue = ModelRegistry.parseOneJsonValue(new StringReader(request));
          return ${javaConstructTypePrefix}jsonValue${javaConstructTypePostfix};
      <#else>
          return context.parsePayload(${javaClassName}.TYPE_ID, I${javaClassName}.class);
      </#if>
        }
      };
      
      out.setWriteListener(manager);
      in.setReadListener(manager);
      <#break>
     
    <#case "Payload">
      // Method has a Payload but no Response
      PayloadOnlyRequestManager<A,${methodPayloadElementType}> manager =
        new PayloadOnlyRequestManager<A,${methodPayloadElementType}>(in, out, auth, context.getTrace(), async, getProcessExecutor())
      {
        @Override
        public void handle(${methodPayloadDecl} payload) throws CanonException
        {
          handle${operation.camelCapitalizedName}(payload, getAuth(), getTrace()<#if operation.parameters?size != 0>,</#if>
      <#list operation.parameters as parameter>
        final${parameter.camelCapitalizedName}<#sep>,</#sep>
      </#list>
          );
        }
      <@setJavaType operation.payload.schema/>
  
        @Override
        protected ${methodPayloadElementType} parsePayload(String request)
        {
      <#if operation.payload.schema.isTypeDef>
          JsonValue<?, ?> jsonValue = ModelRegistry.parseOneJsonValue(new StringReader(request));
          return ${javaClassName}.newBuilder().build(jsonValue);
      <#else>
          return context.parsePayload(${javaClassName}.TYPE_ID, I${javaClassName}.class);
      </#if>
        }
      };
      
      in.setReadListener(manager);
      <#break>
     
    <#case "Response">
      // Method has no Payload but does have a Response
      ResponseOnlyRequestManager<A,${methodResponseElementType}> manager =
        new ResponseOnlyRequestManager<A,${methodResponseElementType}>(in, out, auth, context.getTrace(), async, getProcessExecutor(), getResponseExecutor())
      {
        @Override
        public void handle(IConsumer<${methodResponseElementType}> consumer) throws CanonException
        {
          handle${operation.camelCapitalizedName}(consumer, getAuth(), getTrace()<#if operation.parameters?size != 0>,</#if>
      <#list operation.parameters as parameter>
            final${parameter.camelCapitalizedName}<#sep>,</#sep>
      </#list>
          );
        }
      };
      
      out.setWriteListener(manager);
      
      manager.start();
      <#break>
    
    <#default>
      // Method has neither Payload nor Response
      EmptyRequestManager<A> manager =
        new EmptyRequestManager<A>(in, out, auth, context.getTrace(), async, getProcessExecutor())
      {
        @Override
        public void handle() throws CanonException
        {
          handle${operation.camelCapitalizedName}(getAuth(), getTrace()<#if operation.parameters?size != 0>,</#if>
      <#list operation.parameters as parameter>
        final${parameter.camelCapitalizedName}<#sep>,</#sep>
      </#list>
          );
        }
      };
      
      manager.start();
  </#switch>   
    }
  }
</#list>
}
<#include "/template/java/canon-template-java-Epilogue.ftl">