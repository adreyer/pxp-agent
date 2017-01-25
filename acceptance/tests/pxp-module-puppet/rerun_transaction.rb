require 'pxp-agent/test_helper.rb'


STATUS_QUERY_MAX_RETRIES = 60
STATUS_QUERY_INTERVAL_SECONDS = 1

test_name 'two runs with same transaction_id' do

  step 'Ensure each agent host has pxp-agent running and associated' do
    agents.each do |agent|
      on agent, puppet('resource service pxp-agent ensure=stopped')
      create_remote_file(agent, pxp_agent_config_file(agent), pxp_config_json_using_puppet_certs(master, agent).to_s)
      on agent, puppet('resource service pxp-agent ensure=running')
      show_pcp_logs_on_failure do
        assert(is_associated?(master, "pcp://#{agent}/agent"),
               "Agent #{agent} with PCP identity pcp://#{agent}/agent should be associated with pcp-broker")
      end
    end
  end

  step "run puppet to generate a transaction_id" do
    identity = "pcp://#{agents[0]}/agent"
    target_identities = [identity]
    transaction_id = start_puppet_non_blocking_request(master, target_identities)[0]

      step "verify puppet finished and restart pxp" do
      #  check_puppet_non_blocking_response(identity, transaction_id, STATUS_QUERY_MAX_RETRIES, STATUS_QUERY_INTERVAL_SECONDS, "unchanged")

      agents.each do |agent|
        on agent, puppet('resource service pxp-agent ensure=stopped')
        create_remote_file(agent, pxp_agent_config_file(agent), pxp_config_json_using_puppet_certs(master, agent).to_s)
        on agent, puppet('resource service pxp-agent ensure=running')
        show_pcp_logs_on_failure do
          assert(is_associated?(master, "pcp://#{agent}/agent"),
                 "Agent #{agent} with PCP identity pcp://#{agent}/agent should be associated with pcp-broker")
        end
      end
    end

    step "rerun with same transaction_id" do
      # This should fail!
      #new_tid = start_puppet_non_blocking_request(master, target_identities, 'production', transaction_id)
      response = rpc_request(master, target_identities,
                                                     'pxp-module-puppet', 'run',
                                                     {:flags => ['--onetime',
                                                                 '--no-daemonize',
                                                                 '--environment', 'production']},
                                                                 false,
                                                                 transaction_id)[identity]
      assert(response[:envelope][:message_type] == 'http://puppetlabs.com/rpc_error_message', 'Did not receive rpc error response')
      assert_match(/already exists/, response[:data]['description'], 'Error description does not match')
    end
  end
end # test
