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
    Context "SSL Certificate Verification via OpenSSL" {
        # Execute the exact OpenSSL command string natively through PowerShell's pipeline
        $sslOutput = echo "" | & openssl s_client -servername purva.zenalyst.ai -connect 20.219.60.145:443 2>$null | & openssl x509 -noout -subject -dates

        It "Successfully retrieved OpenSSL data" {
            $sslOutput | Should -Not -BeNullOrEmpty
        }

        It "Has the correct Common Name (Subject)" {
            # Verifies that the correct domain subject is being presented by the target IP
            $sslOutput | Should -Match "CN\s*=\s*purva.zenalyst.ai"
        }

        It "Certificate is currently active (notBefore check)" {
            # Extracts the 'notBefore' date text string out of the multi-line OpenSSL array
            $notBeforeLine = $sslOutput | Where-Object { $_ -match "notBefore=" }
            $notBeforeStr = $notBeforeLine -replace "notBefore=", ""
            $notBeforeDate = [DateTime]::ParseExact($notBeforeStr.Trim(), "MMM  d HH:mm:ss yyyy GMT", [System.Globalization.CultureInfo]::InvariantCulture)
            
            $notBeforeDate | Should -BeLessThan (Get-Date)
        }

        It "Certificate is not expired (notAfter check)" {
            # Extracts the 'notAfter' expiration date text string 
            $notAfterLine = $sslOutput | Where-Object { $_ -match "notAfter=" }
            $notAfterStr = $notAfterLine -replace "notAfter=", ""
            $notAfterDate = [DateTime]::ParseExact($notAfterStr.Trim(), "MMM  d HH:mm:ss yyyy GMT", [System.Globalization.CultureInfo]::InvariantCulture)
            
            $notAfterDate | Should -BeGreaterThan (Get-Date)
        }
    }
}
