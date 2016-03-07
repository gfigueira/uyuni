# Copyright 2016 (c) SUSE LLC
# Licensed under the terms of the MIT license.

When(/^I click on preview$/) do
  find('button#preview').click
end

When(/^I click on run$/) do
  find('button#run').click
end

When(/^I should see my hostname$/) do
  fail if not page.has_content?($myhostname)
end

When(/^I expand the results$/) do
   find("div[id='#{$myhostname}']").click
end

When(/^I expand the results for "(.*)"$/) do |host|
   find("div[id=#{host}]").click
end

When(/^I verify the results$/) do
  within("pre[id='#{$myhostname}-results']") do
    fail if not page.has_content?('.ssh')
    fail if not page.has_content?('spacewalk-testsuite-base')
    fail if not page.has_content?('.bashrc')
  end
end

When(/^"(.*)" exists on the filesystem$/) do |file|
  fail if not File.exists?(file)
end
