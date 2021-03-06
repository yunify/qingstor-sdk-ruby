#  +-------------------------------------------------------------------------
#  | Copyright (C) 2016 Yunify, Inc.
#  +-------------------------------------------------------------------------
#  | Licensed under the Apache License, Version 2.0 (the "License");
#  | you may not use this work except in compliance with the License.
#  | You may obtain a copy of the License in the LICENSE file, or at:
#  |
#  | http://www.apache.org/licenses/LICENSE-2.0
#  |
#  | Unless required by applicable law or agreed to in writing, software
#  | distributed under the License is distributed on an "AS IS" BASIS,
#  | WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  | See the License for the specific language governing permissions and
#  | limitations under the License.
#  +-------------------------------------------------------------------------

require 'json'
require 'digest'
require 'net/http'

require './qingstor-sdk'

# ----------------------------------------------------------------------------

bucket = nil

When(/^put object with key "(.+)"$/) do |object_key|
  bucket = @qs_service.bucket @test_config[:bucket_name], @test_config[:zone]
  raise if bucket.nil?

  system 'dd if=/dev/zero of=/tmp/sdk_bin bs=1024 count=1'
  @put_object_output = bucket.put_object(
    object_key,
    body: File.open('/tmp/sdk_bin'),
  )
  system 'rm -f /tmp/sdk_bin'
end

Then(/^put object status code is (\d+)$/) do |status_code|
  raise unless @put_object_output[:status_code].to_s == status_code.to_s
end

When(/^put object "(.+)" with metadata "(.+)":"(.+)", "(.+)":"(.+)"$/) do |object_key, k1, v1, k2, v2|
  system 'dd if=/dev/zero of=/tmp/sdk_bin bs=1024 count=1'
  @put_object_metadata_output = bucket.put_object(
    "#{object_key}_meta",
    x_qs_meta_data: {"#{k1}": v1, "#{k2}": v2},
    body:           File.open('/tmp/sdk_bin'),
  )
  system 'rm -f /tmp/sdk_bin'
end

Then(/^put object with metadata status code is (\d+)$/) do |status_code|
  raise unless @put_object_metadata_output[:status_code].to_s == status_code.to_s
end

When(/^copy object with key "(.+)"$/) do |object_key|
  @put_the_copy_object_output = bucket.put_object(
    "#{object_key}_copy",
    x_qs_copy_source: "/#{@test_config[:bucket_name]}/#{object_key}",
  )
end

Then(/^copy object status code is (\d+)$/) do |status_code|
  raise unless @put_the_copy_object_output[:status_code].to_s == status_code.to_s
end

When(/^move object with key "(.+)"$/) do |object_key|
  @put_the_move_object_output = bucket.put_object(
    "#{object_key}_move",
    x_qs_move_source: "/#{@test_config[:bucket_name]}/#{object_key}_copy",
  )
end

Then(/^move object status code is (\d+)$/) do |status_code|
  raise unless @put_the_move_object_output[:status_code].to_s == status_code.to_s
end

# ----------------------------------------------------------------------------

When(/^get object with key "(.+)"$/) do |object_key|
  @get_object_output = bucket.get_object object_key
end

Then(/^get object status code is (\d+)$/) do |status_code|
  raise unless @get_object_output[:status_code].to_s == status_code.to_s
end

Then(/^get object content length is (\d+)$/) do |length|
  raise unless (@get_object_output[:body].length * 1024).to_s == length.to_s
end

When(/^get object "(.+)" and check metadata$/) do |object_key|
  @get_object_meta_output = bucket.get_object "#{object_key}_meta"
end

Then(/^get object metadata is "(.+)":"(.+)", "(.+)":"(.+)"$/) do |k1, v1, k2, v2|
  raise unless @get_object_meta_output[:"x_qs_meta_#{k1}"].to_s == v1
  raise unless @get_object_meta_output[:"x_qs_meta_#{k2}"].to_s == v2
end

When(/^get object "(.+)" with content type "([^"]*)"$/) do |object_key, content_type|
  @get_object_output = bucket.get_object object_key,
                                         response_content_type: content_type
end

Then(/^get object content type is "([^"]*)"$/) do |content_type|
  raise unless @get_object_output[:content_type] == content_type
end

When(/^get object "(.+)" with query signature$/) do |object_key|
  @get_object_request = bucket.get_object_request object_key
  @get_object_request.input[:request_headers][:'Content-Type'] = ''
  @get_object_request.sign_query 10
  @get_object_request.build
end

Then(/^get object with query signature content length is (\d+)$/) do |length|
  result = Net::HTTP.get URI.parse @get_object_request.request_url
  raise unless (result.length * 1024).to_s == length.to_s
end

# ----------------------------------------------------------------------------

When(/^head object with key "(.*)"$/) do |object_key|
  @head_object_output = bucket.head_object object_key
end

Then(/^head object status code is (\d+)$/) do |status_code|
  raise unless @head_object_output[:status_code].to_s == status_code.to_s
end

# ----------------------------------------------------------------------------

When(/^options object "(.*)" with method "([^"]*)" and origin "([^"]*)"$/) do |object_key, method, origin|
  @options_object_output = bucket.options_object(
    object_key,
    access_control_request_method: method,
    origin:                        origin,
  )
end

Then(/^options object status code is (\d+)$/) do |status_code|
  raise unless @options_object_output[:status_code].to_s == status_code.to_s
end

# ----------------------------------------------------------------------------

When(/^delete object with key "(.*)"$/) do |object_key|
  @delete_object_output = bucket.delete_object object_key
end

Then(/^delete object status code is (\d+)$/) do |status_code|
  raise unless @delete_object_output[:status_code].to_s == status_code.to_s
end

When(/^delete the move object with key "(.*)"$/) do |object_key|
  @delete_the_move_object_output = bucket.delete_object "#{object_key}_move"
end

Then(/^delete the move object status code is (\d+)$/) do |status_code|
  raise unless @delete_the_move_object_output[:status_code].to_s == status_code.to_s
end

When(/^delete object with metadata and "(.*)"$/) do |object_key|
  @delete_obj_with_meta_output = bucket.delete_object "#{object_key}_meta"
end

Then(/^delete object with metadata status code is (\d+)$/) do |status_code|
  raise unless @delete_obj_with_meta_output[:status_code].to_s == status_code.to_s
end
