"""
Forms for the imputation app.
"""
import json
from django import forms
from django.core.exceptions import ValidationError
from .models import ImputationService


class ServiceSetupForm(forms.ModelForm):
    """Form for setting up imputation services."""
    
    supported_formats = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 2}),
        help_text='JSON array of supported formats, e.g., ["vcf", "vcf.gz", "plink"]',
        initial='["vcf", "vcf.gz"]'
    )
    
    api_config = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 5}),
        help_text='Additional API configuration in JSON format',
        required=False,
        initial='{}'
    )
    
    class Meta:
        model = ImputationService
        fields = [
            'name', 'service_type', 'api_type', 'api_url', 'api_key',
            'description', 'is_active', 'api_key_required',
            'max_file_size_mb', 'supported_formats', 'api_config'
        ]
        widgets = {
            'api_key': forms.PasswordInput(render_value=True),
            'description': forms.Textarea(attrs={'rows': 3}),
        }
    
    def clean_supported_formats(self):
        """Validate and parse supported formats."""
        value = self.cleaned_data['supported_formats']
        try:
            formats = json.loads(value)
            if not isinstance(formats, list):
                raise ValidationError('Supported formats must be a JSON array')
            return formats
        except json.JSONDecodeError:
            raise ValidationError('Invalid JSON format')
    
    def clean_api_config(self):
        """Validate and parse API configuration."""
        value = self.cleaned_data['api_config'] or '{}'
        try:
            config = json.loads(value)
            if not isinstance(config, dict):
                raise ValidationError('API config must be a JSON object')
            return config
        except json.JSONDecodeError:
            raise ValidationError('Invalid JSON format')
    
    def clean(self):
        """Additional validation."""
        cleaned_data = super().clean()
        api_type = cleaned_data.get('api_type')
        api_url = cleaned_data.get('api_url')
        
        if api_url and not api_url.startswith(('http://', 'https://')):
            self.add_error('api_url', 'API URL must start with http:// or https://')
        
        return cleaned_data 