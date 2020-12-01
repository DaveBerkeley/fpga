
#include <stddef.h>

#include <FreeRTOS.h>
#include <task.h>

void vAssertCalled( void )
{
}

void * pvPortMalloc( size_t xSize )
{
    return 0;
}

void vPortFree( void * pv )
{
}

void vApplicationTickHook( void )
{
}

void vApplicationStackOverflowHook( TaskHandle_t xTask, char *pcTaskName)
{
}

StackType_t * pxPortInitialiseStack( StackType_t * pxTopOfStack,
                                        TaskFunction_t pxCode,
                                        void * pvParameters )
{
    return 0;
}

BaseType_t xTimerCreateTimerTask( void )
{
    return 0;
}

//  FIN
