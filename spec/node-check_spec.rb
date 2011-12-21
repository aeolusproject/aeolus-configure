#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

def run_and_check_status (node, expected_exit_status)
  `./bin/aeolus-node-check ./spec/fixtures/nodes/#{node}`
  $?.exitstatus.should be(expected_exit_status), "#{node}"
end


describe "aeolus-node-check" do
  it "error message display" do
    output=`./bin/aeolus-node-check ./spec/fixtures/nodes/no-colon-between-parameter-name-and-value`
    output.should == "Error found in ./spec/fixtures/nodes/no-colon-between-parameter-name-and-value\nIncorrect format found on or before line 5\nparameters must be in the form [space][space][parameter name][colon][space][parameter value]\nclasses must be in the form [dash][space][class name]\n"
  end

  it "should raise an error with these files" do
    run_and_check_status("no-colon-between-parameter-name-and-value", 1)
    run_and_check_status("no-space-between-dash-and-class-name", 1)
    run_and_check_status("no-space-between-parameter-name-and-value", 1)
    run_and_check_status("one-space-before-parameter-name", 1)
    run_and_check_status("three-spaces-before-parameter-name", 1)
  end

  it "should run successful without error" do
    run_and_check_status("good-node-file", 0)
  end
end
