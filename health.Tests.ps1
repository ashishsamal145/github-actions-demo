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
    Context "SSL Certificate Verification" {
        It "SSL certificate subject and dates should be valid for purva.zenalyst.ai" {
            # Run openssl command to get certificate info
            $certInfo = echo | openssl s_client -servername purva.zenalyst.ai -connect 20.219.60.145:443 2>/dev/null | openssl x509 -noout -subject -dates
            
            # Verify that certificate info is not empty
            $certInfo | Should -Not -BeNullOrEmpty
            
            # Parse the output
            $subjectLine = $certInfo | Select-String -Pattern "^subject="
            $notBeforeLine = $certInfo | Select-String -Pattern "^notBefore="
            $notAfterLine = $certInfo | Select-String -Pattern "^notAfter="
            
            # Verify subject contains expected domain
            $subjectLine.ToString() | Should -Match "purva\.zenalyst\.ai"
            
            # Verify dates are present
            $notBeforeLine | Should -Not -BeNullOrEmpty
            $notAfterLine | Should -Not -BeNullOrEmpty
            
            # Parse dates and verify certificate is not expired
            $notAfter = $notAfterLine.ToString() -replace "^notAfter=", ""
            $expiryDate = [datetime]::Parse($notAfter)
            $currentDate = Get-Date
            
            # Check if certificate is still valid (not expired)
            $expiryDate -gt $currentDate | Should -Be $true
            
            # Optional: Check if certificate expires within 30 days (warning)
            $daysUntilExpiry = ($expiryDate - $currentDate).Days
            Write-Host "Certificate expires in $daysUntilExpiry days" -ForegroundColor Yellow
            
            # Verify subject details
            $subject = $subjectLine.ToString() -replace "^subject=", ""
            Write-Host "Certificate Subject: $subject" -ForegroundColor Green
            Write-Host "Valid from: $($notBeforeLine.ToString() -replace '^notBefore=', '')" -ForegroundColor Green
            Write-Host "Valid until: $notAfter" -ForegroundColor Green
        }
    }
    
}
