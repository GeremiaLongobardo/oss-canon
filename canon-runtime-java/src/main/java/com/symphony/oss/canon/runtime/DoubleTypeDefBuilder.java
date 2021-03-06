/*
 *
 *
 * Copyright 2018 Symphony Communication Services, LLC.
 *
 * Licensed to The Symphony Software Foundation (SSF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package com.symphony.oss.canon.runtime;

import com.symphony.oss.commons.dom.json.JsonDouble;
import com.symphony.oss.commons.dom.json.JsonFloat;
import com.symphony.oss.commons.dom.json.JsonInteger;
import com.symphony.oss.commons.dom.json.JsonLong;
import com.symphony.oss.commons.type.provider.IValueProvider;

public abstract class DoubleTypeDefBuilder<M> extends TypeDefBuilder<M,Double>
{
  @Override
  public M build(IValueProvider jsonValue)
  {
    if(jsonValue instanceof JsonDouble)
      return build(((JsonDouble)jsonValue).asDouble());
    
    if(jsonValue instanceof JsonFloat)
      return build((double)((JsonFloat)jsonValue).asFloat());
    
    if(jsonValue instanceof JsonLong)
      return build((double)((JsonLong)jsonValue).asLong());
    
    if(jsonValue instanceof JsonInteger)
      return build((double)((JsonInteger)jsonValue).asInteger());
    
    throw new IllegalArgumentException("Expected a double but found a " + jsonValue.getClass().getName());
  }

}
