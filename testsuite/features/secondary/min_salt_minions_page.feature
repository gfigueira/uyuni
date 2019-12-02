# Copyright (c) 2015-2019 SUSE LLC
# Licensed under the terms of the MIT license.

Feature: Management of minion keys
  In Order to validate the minion onboarding page
  As an authorized user
  I want to verify all the minion key management features in the UI

  Scenario: Delete SLES minion system profile before exploring the onboarding page
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Delete System"
    Then I should see a "Confirm System Profile Deletion" text
    When I click on "Delete Profile"
    And I wait until I see "has been deleted" text
    Then "sle_minion" should not be registered

  Scenario: Completeness of the onboarding page
    Given I am authorized with the feature's user
    And I go to the minion onboarding page
    Then I should see a "Keys" text in the content area

  Scenario: Minion is visible in the Pending section
    Given I am authorized with the feature's user
    And I restart salt-minion on "sle_minion"
    And I wait at most 10 seconds until Salt master sees "sle_minion" as "unaccepted"
    And I go to the minion onboarding page
    And I refresh page until I see "sle_minion" hostname as text
    Then I should see a "Fingerprint" text
    And I see "sle_minion" fingerprint
    And I should see a "pending" text

  Scenario: Reject and delete the pending key
    Given I am authorized with the feature's user
    And I go to the minion onboarding page
    And I reject "sle_minion" from the Pending section
    And I wait at most 10 seconds until Salt master sees "sle_minion" as "rejected"
    Then I should see a "rejected" text
    # we stop the service so the minion does not resubmit its key spontaneously
    When I stop salt-minion on "sle_minion"
    And I delete "sle_minion" from the Rejected section
    And I refresh page until I do not see "sle_minion" hostname as text

  Scenario: Accepted minion shows up as a registered system
    Given I am authorized with the feature's user
    When I start salt-minion on "sle_minion"
    And I wait at most 10 seconds until Salt master sees "sle_minion" as "unaccepted"
    Then "sle_minion" should not be registered
    When I go to the minion onboarding page
    Then I should see a "pending" text
    When I accept "sle_minion" key
    And I wait at most 10 seconds until Salt master sees "sle_minion" as "accepted"
    And I wait until onboarding is completed for "sle_minion"
    Then "sle_minion" should be registered

  Scenario: The minion communicates with the Salt master
    Given I am authorized with the feature's user
    And the Salt master can reach "sle_minion"
    When I get OS information of "sle_minion" from the Master
    Then it should contain the OS of "sle_minion"

  Scenario: Delete profile of unreacheable minion
    Given I am on the Systems overview page of this "sle_minion"
    When I stop salt-minion on "sle_minion"
    And I follow "Delete System"
    Then I should see a "Confirm System Profile Deletion" text
    When I click on "Delete Profile"
    Then I wait until I see "Cleanup timed out. Please check if the machine is reachable." text
    When I click on "Delete Profile Without Cleanup"
    And I wait until I see "has been deleted" text
    Then "sle_minion" should not be registered

  Scenario: Cleanup: bootstrap again the minion
    Given I am authorized with the feature's user
    When I go to the bootstrapping page
    Then I should see a "Bootstrap Minions" text
    When I enter the hostname of "sle_minion" as "hostname"
    And I enter "22" as "port"
    And I enter "root" as "user"
    And I enter "linux" as "password"
    And I select the hostname of "proxy" from "proxies"
    And I click on "Bootstrap"
    And I wait until I see "Successfully bootstrapped host!" text
    And I wait until onboarding is completed for "sle_minion"

  Scenario: Cleanup: restore channels on the minion
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Software" in the content area
    Then I follow "Software Channels" in the content area
    And I wait until I do not see "Loading..." text
    And I check radio button "Test-Channel-x86_64"
    And I wait until I do not see "Loading..." text
    And I click on "Next"
    Then I should see a "Confirm Software Channel Change" text
    When I click on "Confirm"
    Then I should see a "Changing the channels has been scheduled." text
    And I wait until event "Subscribe channels scheduled" is completed

  Scenario: Cleanup: turn the SLES minion into a container build host after new bootstrap
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Details" in the content area
    And I follow "Properties" in the content area
    And I check "container_build_host"
    And I click on "Update Properties"

  Scenario: Cleanup: turn the SLES minion into a OS image build host after new bootstrap
    Given I am on the Systems overview page of this "sle_minion"
    When I follow "Details" in the content area
    And I follow "Properties" in the content area
    And I check "osimage_build_host"
    And I click on "Update Properties"
    Then I should see a "OS Image Build Host type has been applied." text
    And I should see a "Note: This action will not result in state application" text
    And I should see a "To apply the state, either use the states page or run state.highstate from the command line." text
    And I should see a "System properties changed" text

  Scenario: Cleanup: apply the highstate to build host after new bootstrap
    Given I am on the Systems overview page of this "sle_minion"
    When I wait until no Salt job is running on "sle_minion"
    And I enable repositories before installing Docker
    And I apply highstate on "sle_minion"
    And I wait until "docker" service is active on "sle_minion"
    And I wait until file "/var/lib/Kiwi/repo/rhn-org-trusted-ssl-cert-osimage-1.0-1.noarch.rpm" exists on "sle_minion"
    And I disable repositories after installing Docker

  Scenario: Cleanup: check that the minion is now a build host after new bootstrap
    Given I am on the Systems overview page of this "sle_minion"
    Then I should see a "[Container Build Host]" text
    Then I should see a "[OS Image Build Host]" text
