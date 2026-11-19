#include <stdio.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>

#define STACKSIZE (1024)
#define PRIORITY (1)
#define blue_led DT_ALIAS(led0)

static struct gpio_dt_spec spec = GPIO_DT_SPEC_GET(blue_led, "");
static struct k_thread tcb;

K_THREAD_STACK_DEFINE(tstack, STACKSIZE);

static void hello_world_thread(void *, void *, void *) {
  int previous = 0;
  gpio_pin_configure_dt(&spec, 0);
  while (1) {
    // printf("Hello from Thread!\n");
    int result = gpio_pin_set_dt(&spec, previous);
    previous = !previous;
    k_sleep(K_SECONDS(1));
  }
}

int main(void) {
  printf("Hello World! %s\n", CONFIG_BOARD_TARGET);

  k_tid_t tid = k_thread_create(&tcb, tstack, STACKSIZE, hello_world_thread,
                                NULL, NULL, NULL, PRIORITY, 0, K_NO_WAIT);

  if (!tid) {
    return -1;
  }

  k_thread_join(&tcb, K_FOREVER);

  printf("Feierabend\n");

  return 0;
}
