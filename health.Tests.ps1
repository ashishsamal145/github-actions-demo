Describe "Endpoint Regression Tests" {
    BeforeAll {
        $ProgressPreference = 'SilentlyContinue'
    }

    Context "HTTP Status Code Verification" {
        It "Frontend returns 200 OK" {
            $response = Invoke-WebRequest -Uri "https://purva.zenalyst.ai/" -Method Get -MaximumRedirection 0 -SkipHttpErrorCheck
            $response.StatusCode | Should -Be 200
        }

        It "Backend returns 200 OK" {
            $response = Invoke-WebRequest -Uri "https://purva.zenalyst.ai/api/backend/api/health" -Method Get -SkipHttpErrorCheck
            $response.StatusCode | Should -Be 200
        }

        It "AI Engine returns 200 OK" {
            $response = Invoke-WebRequest -Uri "https://purva.zenalyst.ai/api/ai-engine/health" -Method Get -SkipHttpErrorCheck
            $response.StatusCode | Should -Be 200
        }

        It "HTTP redirects to HTTPS (301)" {
            $response = Invoke-WebRequest -Uri "http://zenalyst.ai" -Method Get -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction SilentlyContinue
            $response.StatusCode | Should -Be 301
        }
    }
}
