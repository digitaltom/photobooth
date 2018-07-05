photoBoothApp.controller('MainCtrl', [
  '$scope',
  '$http',
  '$uibModal',
  '$log',
  '$rootScope',
  '$timeout',
  '$interval',
  function ($scope, $http, $uibModal, $log, $rootScope, $timeout, $interval) {

    $scope.shoot_step = function (counter, delay) {
      $timeout(function() {
        $rootScope.current_shoot = counter;
        $rootScope.shoot_progress = 25*counter;
        $rootScope.shoot_progress_txt = counter + ' / 4';
      }, delay);
    }

    $scope.takePicture = function () {

      $rootScope.current_shoot = 0;
      $rootScope.shoot_txt = 'Take pose!';
      $rootScope.shoot_progress_txt = '';
      $scope.openShootModal();

      // ms before shooting
      var countdown_delay = 2000;
      // ms for each camera picture
      var picture_delay = 4000;

      $rootScope.shoot_progress = 100;
      countdown = $interval(function() {
        $rootScope.shoot_progress = $rootScope.shoot_progress - 5;
        if ($rootScope.shoot_progress <= 0) { $interval.cancel(countdown); }
      }, countdown_delay/20);

      $timeout(function() {
        $rootScope.shoot_txt = 'Action, taking 4 pictures';
        $http({
          method: 'POST',
          url: '/picture_sets.json'
        }).then(
          function successCallback(response) {
            $scope.closeShootModal();
            $scope.picture_sets.unshift(response.data);
          },
          function errorCallback(response) {
            $scope.closeShootModal();
            $rootScope.alerts.push({type: 'danger', msg: response.data.error});
          }
        );
      }, countdown_delay);

      $scope.shoot_step(1, picture_delay * 1 + countdown_delay);
      $scope.shoot_step(2, picture_delay * 2 + countdown_delay);
      $scope.shoot_step(3, picture_delay * 3 + countdown_delay);
      $scope.shoot_step(4, picture_delay * 4 + countdown_delay);

      $timeout(function() {
        $rootScope.current_shoot = 5;
        $rootScope.shoot_txt = 'Processing animation';
      }, picture_delay * 5 + countdown_delay);

    };

    $scope.update = function () {
      $http({
        method: 'GET',
        url: '/picture_sets.json'
      }).then(function successCallback(response) {
        $scope.picture_sets = response.data;
      }, function errorCallback(response) {
        $rootScope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $scope.openShootModal = function () {
      $scope.shootModalInstance = $uibModal.open({
        animation: true,
        size: 'lg',
        templateUrl: 'picture_shoot.html'
      });
    };

    $scope.closeShootModal = function () {
      $scope.shootModalInstance.dismiss('cancel')
    }

    $scope.update();

    $scope.rw = (location.search != '?rw/');

  }]);
