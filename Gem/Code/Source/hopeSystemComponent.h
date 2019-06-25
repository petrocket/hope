#pragma once

#include <AzCore/Component/Component.h>

#include <hope/hopeBus.h>

namespace hope
{
    class hopeSystemComponent
        : public AZ::Component
        , protected hopeRequestBus::Handler
    {
    public:
        AZ_COMPONENT(hopeSystemComponent, "{90EDC3F6-5835-4716-A3B6-2A8BCDDE9576}");

        static void Reflect(AZ::ReflectContext* context);

        static void GetProvidedServices(AZ::ComponentDescriptor::DependencyArrayType& provided);
        static void GetIncompatibleServices(AZ::ComponentDescriptor::DependencyArrayType& incompatible);
        static void GetRequiredServices(AZ::ComponentDescriptor::DependencyArrayType& required);
        static void GetDependentServices(AZ::ComponentDescriptor::DependencyArrayType& dependent);

    protected:
        ////////////////////////////////////////////////////////////////////////
        // hopeRequestBus interface implementation

        ////////////////////////////////////////////////////////////////////////

        ////////////////////////////////////////////////////////////////////////
        // AZ::Component interface implementation
        void Init() override;
        void Activate() override;
        void Deactivate() override;
        ////////////////////////////////////////////////////////////////////////
    };
}
