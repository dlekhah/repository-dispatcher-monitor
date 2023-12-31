  CLIENT_PAYLOAD=$PAY

  
  response=$(curl -L -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GITHUB_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" -w "%{http_code}" https://api.github.com/repos/$OWNER/$REPO/dispatches -d '{"event_type":"'"$EVENT"'","client_payload":'"$CLIENT_PAYLOAD"'')
  http_code=${response:${#response}-3}  # Extract the HTTP status code
  sleep 10
  if [[ $http_code -eq 204 ]]; then
    workflows=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$OWNER/$REPO/actions/runs?event=repository_dispatch&event_id=$EVENT")
    run_id=$(echo "$workflows" | jq -r '.workflow_runs[] | .id' | head -n 1)
    run_url=$(echo "$workflows" | jq -r '.workflow_runs[] | .html_url' | head -n 1)
    if [[ -n "$run_id" ]]; then
      echo "workflow run ID: $run_id"
      echo "url: $run_url"
      run_status=""
      while [[ "$run_status" != "completed" ]]; do
        run_status=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$run_id" | jq -r '.status')
        run_result=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$run_id" | jq -r '.conclusion')
        jobs_response=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$run_id/jobs")
        jobs=$(echo "$jobs_response" | jq -r '.jobs[]  | "\(.name): status - [\(.status)] result - [\(.conclusion)]"')
        echo ".................."
        echo "Pipeline progress:"
        echo "$jobs"
        echo "url: $run_url"
        echo ".................."
        if [[ "$run_status" == "completed" ]]; then
          if [[ "$run_result" == "failure" ]]; then
              # Add your logic here for handling the completed workflow run
              echo "Workflow completed!"
              echo "Result: $run_result"
              exit 1
              break
          else
              # Add your logic here for handling the completed workflow run
              echo "Workflow completed!"
              echo "Result: $run_result"
              break
          fi
       else
          echo "refreshing status in $STATUS_REFRESH_TIME seconds..."
          sleep $STATUS_REFRESH_TIME
      fi
      done
    else
      echo "$REPO workflow not found"
      exit 1
    fi
  else
    echo "API call failed with status code $http_code"
    exit 1
  fi 
